---
title: Migrating a Legacy PHP Application To Heroku
created_at: 2014-07-15 17:47:37 -0400
kind: article
---

**Wow, that was easy!** -Me

Last time I looked at doing PHP on Heroku it was pretty scary and involved creating custom buildpacks.

Today, I read <a href="https://blog.heroku.com/archives/2014/4/29/introducing_the_new_php_on_heroku">Introducing the new PHP on Heroku</a> and set out to migrate over a tool I wrote 5+ years ago from a LAMP server over to Heroku. The end result: <a href="http://xtrack.ckdake.com/">xtrack.ckdake.com</a>.

## The Basics

Migrating from subversion to git. <a href="https://github.com/nirvdrum/svn2git">git2svn</a> makes this really easy. Creating an app on Heroku and pushing to it is the usual easy <code>heroku create</code> and <code>git push heroku master</code>, and hooray, I was done! Not quite...

## Database

My old code used PHP's old built-in support for MySQL (<code>mysql_connect</code>) which has been replaced with the shiny new MySQL extension (<code>mysqli_connect</code>). Getting rid of the first errors in the log that prevented the app from building meant switching to <code>mysqli_*</code> functions everywhere, and passing around the <code>$link</code> to objects/methods that needed it. Had my app been 'modern' PHP code, this wouldn't have been needed.

For actually hosting the database, Heroku has an addon for MySQL: <a href="https://addons.heroku.com/cleardb">ClearDB</a>. It's free for 5MB of data which is plenty for this app. This was as simple as <code>heroku addons:add cleardb</code>. I added a little bit of logic to pull in the CLEARDB_DATABASE_URL:

<pre><code class="language-php">
$url = parse_url(getenv("CLEARDB_DATABASE_URL"));

$server = $url["host"];
$user   = $url["user"];
$pass   = $url["pass"];
$db     = substr($url["path"], 1);

$link = mysqli_connect($server, $user, $pass, $db) or die(mysqli_error());
</code></pre>


And was in business. Getting the data loaded in was as easy as grabbing a snapshot from my old production server and running something along the lines of <code>cat dump.sql | mysql -u$USER -p $HOST $DB</code> and everything worked great. I did have an old 'loader' script that relied on MySQL's "LOAD INFILE", but this doesn't work with ClearDB.

## The Good And The Bad

The good news is that I don't need this app co-habitating space with my (now static) homepage. It's one less thing to worry about. The bad is that Heroku will idle out my process when it's not hit in a while so the first time someone visits will be awfully slow sometimes. I'm the only target user, so I think I'll be alright. For playing with PHP apps in the future, I'll definitely consider using Heroku and so should you.
