---
title: A Shiny New Website
created_at: 2014-07-09 14:14:37 -0400
kind: article
---

It's been 8 years since I last switched web platforms for ckdake.com, and it was time for a change. We are <a href="http://galleryproject.org/time-to-hibernate">putting Gallery into hibernation</a>, Drupal 6 is not going to get any more security updates once Drupal 8 is out (which should be soon), and the ongoing server/backup costs of keeping 130GB of photos on my site is not cheap.

We recently launched a new <a href="http://www.bignerdranch.com/">bignerdranch.com</a> at work, and my team did a fantastic job of building it as a 'static' site using <a href="http://jekyllrb.com">jekyll</a> that included migrating a bunch of legacy Python, PHP, and Ruby code including an old Wordpress site.

With fantastic services like Flickr for photos and Vimeo for video, I set out to migrate my photos to Flickr and build a simple and fast 'static' site for ckdake.com. Here it is! The theme still needs a lot of work which is fine, and <a href="http://nanoc.ws">nanoc</a> has been a lot of fun to get up and running.

# Migrating Photos to Flickr

Flickr has a pretty straightforward API, and the <a href="https://github.com/hanklords/flickraw">Flickraw</a> gem makes writing ruby code to talk to Flickr pretty easily. A few weeks ago I started on this and published the script that migrated my ~25,000 photos to Flickr here: <a href="https://gist.github.com/ckdake/612bdaa1a8333ac37b17">gallery2flickr.rb</a>.

This took about a week to run, and afterwards I spent a good bit of time properly naming sets, changing privacy settings, and copying over captions from my 'stream' abums. More time on the script could have automated some of this, but it's done.

Getting Flickr Photos displayed here was a pretty straightforward block of Ruby code:

<script src="https://gist.github.com/ckdake/37562c058673e74d5874.js?file=flickr.rb"></script>

# Pulling in Vimeo

Vimeo was really easy to pull in to, and the end result looks much better than the JavaScript widget I was using. It's Ruby:

<script src="https://gist.github.com/ckdake/37562c058673e74d5874.js?file=vimeo.rb"></script>

# Preserving content and URLs

Getting content out of Drupal was a little bit more involved, and I didn't spend the time to match up the 'format' of blog posts with file extensions or a content formatter. That might be nice, but I'm ok just fixing HTML files by hand when I notice something wonky. This script pulled out my content:

<script src="https://gist.github.com/ckdake/37562c058673e74d5874.js?file=drupal-to-text.php"></script>

And here is the full 'Rules' file for nanoc that keeps around my old blog and page URLs. Note that nanoc by default does things like '/folder/page/index.html' so I've configured it to do '/folder/page.html' instead.

<script src="https://gist.github.com/ckdake/37562c058673e74d5874.js?file=Rules.rb"></script>
