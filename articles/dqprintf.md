<!--
{
    "title": "dqprintf",
    "post_date": "2011-07-26 10:47 AM",
    "tags": ["postgres"]
}
-->

Part of my job involves performing data transformations using tables loaded via
CSVs, which themselves were created from tab-delimited reports. Nasty.

Making something usable out of these involves a nice handful of PL/PGSQL
functions. These functions involve arguments specifying table names and other
values that are used to build dynamic queries that either perform
`INSERT ... SELECT FROM`, or loop through result sets because the reports
require some amount of contextual processing before performing an `INSERT`.
Blech.

The two main functions that make this all possible are `quote_ident` and
`quote_literal`. They ensure you're not just blindly concatenating illegal
identifier names into your queries. Please don't just type in
`" || table_name || "`. It hurts.

Unfortunately, your function will inevitably end up looking a little like this:

    iQuery := $Q$
        SELECT
            $Q$ || quote_ident(some_column) || $Q$ || $Q$ ||
                quote_literal(some_value) || $Q$ || '-1'
        FROM $Q$ || quote_ident(some_table) || $Q$
        WHERE another_column = $Q$ || quote_literal(another_value) || $Q$
    $Q$;

    FOR mRow IN EXECUTE iQuery
    LOOP
    ...

Gross, but this isn't a new problem, so here's a simple solution.

I adapted [this function](http://wiki.postgresql.org/wiki/Sprintf Sprintf) a
bit to make `dqprintf`, a simple `sprintf`-like function to create dynamic
queries:


    CREATE OR REPLACE FUNCTION dqprintf(fmt text, VARIADIC args anyarray)
    RETURNS text
    LANGUAGE PLPGSQL AS $$
    DECLARE
            argcnt int = 1;
            chrcnt int = 0;
            fmtlen int;
            CHR text;
            NEXT_CHR text;
            output text = '';
            curarg text;
            
    BEGIN
            fmtlen = LENGTH(fmt);
            LOOP
                    chrcnt = chrcnt + 1;

                    -- ran out of format string? bail out
                    IF chrcnt > fmtlen THEN
                            EXIT;
                    END IF;

                    -- grab our char
                    CHR = substring(fmt, chrcnt, 1);
                    NEXT_CHR = substring(fmt, chrcnt + 1, 1);

                    -- %% means output a single %, and skip them
                    IF CHR = '%' AND substring(fmt, chrcnt + 1, 1) = '%' THEN
                            output = output || '%';
                            chrcnt = chrcnt + 1;
                            continue;
                    END IF;

                    -- %i means we're going to quote an identifier
                    -- %l means we're going to quote a literal
                    -- %s is anything else. Not exactly a printf format.
                    IF CHR = '%' THEN
                            curarg := COALESCE(args[argcnt]::text, '');
                            
                            IF NEXT_CHR = 'i' THEN
                                curarg := quote_ident(curarg);
                            ELSIF NEXT_CHR = 'l' THEN
                                curarg := quote_literal(curarg);
                            ELSIF NEXT_CHR <> 's' THEN
                                -- improper format identifier
                                RAISE EXCEPTION 'Incorrect format identifier: %', NEXT_CHR;
                            END IF;
                            
                            output = output || curarg;
                            argcnt = argcnt + 1;
                            chrcnt = chrcnt + 1;
                            CONTINUE;
                            
                    END IF;

                    -- no special case? output the thing
                    output = output || CHR;
            END LOOP;

            RETURN output;
    END;
    $$;

This will turn the above pipe character mess into something a bit more manageable:

    iQuery := $Q$
        SELECT
            %i || %l || '-1'
        FROM %i
        WHERE another_column = %l
    $Q$;
    FOR mRow IN EXECUTE dqprintf(iQuery, some_column, some_value,
        some_table, another_value)
    LOOP
    ...

A couple of notes. First, every argument needs to be cast to the same type,
preferably `text`. If you're using this in a PL/PGSQL function, you most likely
have this covered if these are typed arguments to the function already.

Secondly, error handling isn't terribly robust, so debugging it might be
clumsy. You're already used to that, though, if you're writing PL/PGSQL
functions.