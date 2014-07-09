---
title: The Uncanny Valley, The Pareto Principle, and end-user facing Software Development
created_at: 2012-10-01 16:41:26 -0400
kind: article
---
That software project you have in mind? You are not going to make everyone happy, so don't attempt to please everyone.

<blockquote>"The uncanny valley is a hypothesis in the field of robotics and 3D computer animation, which holds that when human replicas look and act almost, but not perfectly, like actual human beings, it causes a response of revulsion among human observers. The "valley" refers to the dip in a graph of the comfort level of humans as a function of a robot's human likeness." - <a href="http://en.wikipedia.org/wiki/Uncanny_valley">wikipedia</a></blockquote>

If you saw 'The Polar Express' and something seemed off, you know exactly what this is.  Something close to our expectations of 'right' but that isn't quite there is going to be uncomfortable. This applies not just to human figures, but to anything that we have expectations about. From ice cream flavors that are so close to some flavor that they are gross, to snakes with creepy faces [<a href="http://en.wikipedia.org/wiki/Uncanny_valley#cite_note-42">ref</a>] to software that doesn't quite work right.

<blockquote>"The Pareto principle (also known as the 80–20 rule, the law of the vital few, and the principle of factor sparsity) states that, for many events, roughly 80% of the effects come from 20% of the causes." - <a href="http://en.wikipedia.org/wiki/Pareto_principle">wikipedia</a></blockquote>

This is commonly called the 80/20 rule in software, and can be extrapolated to things like:

<ul>
<li>80% of the needs of potential users can be met with 20% of the features</li>
<li>20% of the effort can acomplish 80% of the functionality</li>
</ul>

The fact that 80 and 20 add up to 100 is a mere concidence here, and something like "80% of the features can be acomplished by 5% of the code" would still fit this principle.

I propose that these two concepts can be combined together to predict a specific way that software projects can be guaranteed to fail or cause frustration to users. To start, a personal example:

<blockquote>Apple iCloud contact syncing is awesome. Like many Apple products, it just works: I edit the phone number for a contact on my computer, and seconds later the contact on my phone is updated and the next time I call them it will use the right number. I can create contact groups and they sync around as well.  However, there is a concept of 'starred contacts' on my phone which doesn't seem to appear anywhere else.  I forget how great the synchronization is because it's so frustrating that I can't work with the list of 'starred' contacts on my computer, and I waste time trying to find workarounds like making a 'starred' group which is less than perfect. As contact lists tie in with other things like Messages, this gets even more frustrating as groups of contacts are inconsistent across more devices and applications. Because of how much "Just Works", is it really too much to ask for my starred contacts to sync between Messages and my Phone?</blockquote>

Because Apple got things so close to perfect, I am frustrated instead of amazed. If they gave me a little less, or got things perfectly right I'd be a lot happier but I'm in an 'Uncanny valley'-ish hole of frustration and time wasting instead, which is the opposite of what I want from technology designed to make me more productive. 

At <a href="http://highgroove.com/">Highgroove</a>, we develop custom web applications for a pretty diverse base of customers. Our clients have a good idea of what they want to happen and we help them break it down into the tiny pieces. A 'Minimum Viable Product' line gets drawn in the sand and features get prioritized before or after this. Chances are pretty good that infinite scroll and auto-resizing profile images will be awesome, but they probably aren't needed to launch.  We know from tons of experience that if the MVP marker gets pushed back in any significant way, there is almost no chance that our customer will get what they 'want' regardless of how much more development effort is on the schedule.

In software, there are always new ideas so to finish 'everything' would take an infinite amount of time. '<a href="http://en.wikipedia.org/wiki/The_Mythical_Man-Month">The Mythical Man Month</a>' points out that  software projects are almost always considered unstarted or 90% done, but never finished, and any project that attempts perfection will not ever be completed on time or under budget (if even at all).

The lesson here is that attempting to spec out and complete functionality to meet the needs of every potential user of your application is an insurmountable task. The 80/20 rule applied here (80% of the needs with 20% of the features) tells us that we'll save tons of time and effort by skipping out on a few things, and the Uncanny Valley tells us that unless we get things absolutely perfect (which never happens), we'll be stuck in a hole of user frustration due to things being close but not quite right.

So come up with crazy ideas and tons of features for your app, but put in the effort to prioritize what is really important and get that done first so that you can ship something that causes delight instead of disappointment. 95% of the way there is closer to 0% than you think, and if you stick to something more realistic, you'll ship something that your users love before you even realize it.