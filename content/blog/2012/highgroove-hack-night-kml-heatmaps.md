---
title: "Highgroove Hack Night: KML Heatmaps"
created_at: 2012-04-24 10:02:51 -0400
kind: article
---
Every month, <a href="http://highgroove.com/">Highgroove</a> hosts a hack night where we order food, stock up on beer, and invite anyone and everyone to come hang out in our office to work on cool projects.  Last night was a pretty busy one with a handful of open-source gems getting updated, and between helping out other people and building <a href="http://ckdake.com/gallery/2012/stream/photo_036.JPG.html">Space Cthulhu</a> I played with turning GPS traces of bike rides into a heatmap.

First up was getting coordinate data for the heatmap out of Google Earth.  I put together a quick script using nokogiri and ruby to grab the coordinates from a kml file and output them to CSV:

<script src="https://gist.github.com/2479821.js?file=mykml2csv.rb"></script>

This gets run like:

<pre>ruby mykml2csv.rb > coords.csv</pre>

Then, I used <a href="http://jjguy.com/heatmap/">heatmap.py</a> in python to generate both an image and a KML overlay:

<script src="https://gist.github.com/2479821.js?file=csv2map.py"></script>

This gets run like:

<pre>python csv2map.py</pre>

For my 2007 kml this was only ~3000 points and worked pretty quickly, but for 2008 there are ~60k points and I had to shrink dot size and bump up output size pretty significantly to get it to finish.  csv2map.py ran for ~12 hours and finally outputted a pretty neat image:

<img src="http://ckdake.com/files/google-earth-heatmap.jpg">

Looks like I rode to Stone Mountain a lot in 2008. This could probably be generated in a few seconds with a more performant heatmap library, so perhaps I'll hack one of those together in the future.  That said, this was a fun proof of concept and may be useful for people with smaller KML files than me!  My entire my.kml has over 1 Million points, so it may never build a heatmap of all of them.
