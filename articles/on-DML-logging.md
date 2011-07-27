<!--
{
    "title": "On DML Logging",
    "post_date": "2011-07-24 08:21 AM",
    "tags": ["postgres"]
}
-->

If your shop is like ours, your devs working with PostgreSQL want to log
UPDATE, INSERT and DELETE operations by users, as a tool to analyze bugs in
your software or to audit user activities. Trigger functions immediately jump
to mind, and they are rightfully suited to the task, but bring some baggage of
their own that may give you some pause if your users or developers are
sensitive to the speed of their database queries.

First things first, PL/PGSQL is great. If you absolutely can't write your
function in plain SQL, use PL/PGSQL if you can. PL/Python is fun, very
powerful, and if you're like me, writing Python is like a Slip 'N Slide that
never ends. But for trigger functions on what could be millions of queries, it
may give you the gift of a significant performance penalty that will irritate
you for around a year before it finally prompts you to complain about it in
writing, on the Internet.

Unfortunately for PL/PGSQL, the trigger function's row object doesn't provide
any sort of data you can use to find out exactly _what_ fields are contained
within the row object. You also can't dynamically refer to these columns in
the row variable. You have to infer this from the table you created the
trigger on, and write your function appropriately.  So, that works...if you're
logging a single table. Fast forward to writing trigger functions for 40 or
more tables and you see the dilemma.

So, long story made short, PL/Python trigger functions provide rows as a Dict,
and it's fairly obvious what to do with it. But then there's a performance hit.
It's not even so much the OLTP queries that drag us down as the data loading.
Like most people dealing with real data, you have to load quite a bit from time
to time, and if you're nice, you won't grab an exclusive lock on the entire
table and disable triggers just so you can bring in a few years of history.

You can see where this is going. Every row inserted brings you another single
INSERT to your logging table. It doesn't matter what structure you've made
for storing this log data, it's going to be painful.

You could include code in the trigger function to turn around and exit if it
sees a specially named session-local temporary table. This takes off some of
the hit from the INSERTs. But, you're still firing off the Python interpreter
500,000 times if you're creating 500,000 records.

That leaves us with some options.

*  Write the trigger function in another PL that isn't as slow. It'll probably
   still be slow.
*  Write the trigger function in C. Without putting buckshot in your own foot.
*  Write a function that writes a PL/PGSQL function. Dynamically generate a
   trigger function for each table that performs the appropriate INSERTS,
   per-column by effectively unlooping your FOR loop.

The last one is crazy enough that it might work, but I haven't even tried to
test it yet.