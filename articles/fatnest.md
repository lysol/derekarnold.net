<!--
{
    "title": "Fatnest, and Flask",
    "post_date": "2012-09-16 03:30 PM",
    "tags": ["twitter", "python", "postgres", "flask", "candle"]
}
-->

I made [a site](http://fatnest.com) that solves a smallish problem with Twitter:
delegating access to tweets without also giving access to the
rest of the account, including the password.

Basic workflow is sign in with your email address, add a Twitter
account, then delegate tweeting access to other email addresses.
There's a feature where you can share a semi-private URL for submitting
tweets for further moderation, as well. Even with the hostility towards
developers from Twitter, it's still a compelling platform that as at least
few years left in it before it's no longer cool for developers with screw
with in their spare time.

The app was written in my spare time over the last couple of weeks, using
[Flask](http://flask.pocoo.org/), [Postgres](http://postgresql.org)
and another library I wrote specifically for this named
[Candle](http://github.com/lysol/candle).

After making the rounds with development with node.js, Python, and PHP
in the last couple of years, the clear winner for me is Python and Flask.
Flask leverages Python in the right ways, and lets the developer keep the
project within his/her headspace, which is important for maintaining scope.

I've also taken to using Postgres's
[hstore](http://www.postgresql.org/docs/9.1/static/hstore.html) data type as a
poor man's memcached. Because, hey, databases are made for caching. So just
use the database, man.
