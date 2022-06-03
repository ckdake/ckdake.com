---
title: Building A Smarter Sprinkler System
created_at: 2022-05-25 20:40:37 -0400
kind: article
tags: [project]
project_name: Smarter Sprinkler
---

I moved into a house a year ago, and with some time between jobs finally had some time to get through a pile of projects. The existing sprinkler system controller turns on when it is not supposed to, and forgets everything whenever the power blips, which has been happening a lot.

This project (unfortunately) didn't require buying any new tools, saved spending $100+ on a gadget, and hooks together a a handful of things pretty smoothly. Finished photo first:

<div class="embedimg"><img src="/img/blog/2022/sprinkler-finished.jpg" style="width: 50%;"/></div>

<!-- more -->

## The Hardware

What initially appeared to be a "smart" "two-wire" fancy system turned out to only have two wires because it only controls a single zone with a single solenoid. Great.  24V AC turns it on, no 24V AC turns it off.  The existing controller had a 24V AC power adapter so all I needed was a way to switch the power on and off to the solenoid through existing wiring, automatically, on a schedule, and ideally taking into account the weather.

I did a little too much research, did some handwaving on the [Tech 404 Slack](https://tech404.github.io) with an old coworker, and went and spend $7 on [Adafruit](https://www.adafruit.com) for a few parts.  I already had an old Rasberry Pi B+ hanging out, so a few days later a [Non-Latching mini relay](https://www.adafruit.com/product/4409) showed up with a cable to attach it to the pi's GPIO pins: [STEMMA JST PH 2mm 3-Pin to Female Socker Cable](https://www.adafruit.com/product/3894). 

With some quick cutting/twisting/plugging and one existing wiring nut, I had the Pi connected to the relay, managing the 24V to the sprinkler system, and it worked via a few lines of python using CircuitPy.  

<div class="embedimg"><img src="/img/blog/2022/sprinkler-wiring.jpg" style="width: 50%;"/></div>


## The Software

sshing to a computer and running a command is not a great way to turn a sprinkler system on, so it was time to hack some things together. First up was getting it responding to HTTP requests, and I spun up a simple web server to run in a `screen` sesion and turn the relay on and off. This would be better as a system daemon that starts on boot, but that is easy enough to fix later:

<pre><code class="language-python">
import time
import board
import digitalio
import web

status = False
relay = digitalio.DigitalInOut(board.D26)
relay.direction = digitalio.Direction.OUTPUT
relay.value = False

urls = ('/(.*)', 'call')

class call:
    global status
    def GET(self, action):
        global status
        if (action == 'status'):
            if status:
                return 1
            else:
                return 0
        return "Beep bo beep!"
    def POST(self, action):
        global status
        if (action == 'on'):
            status = True
            relay.value = status
        elif (action == 'off'):
            status = False
            relay.value = status
        return "Beep bo beep beep!"


if __name__ == "__main__":
    app = web.application(urls, globals())
    app.run()
</code></pre>

Next was connecting this to homebridge using Andi's simple and well-documented [homebridge-http-switch Plugin](https://github.com/Supereg/homebridge-http-switch#readme). This exposes a virtual switch in HomeBridge (and thus HomeKit and a button on my phont) to turn the realy on and off. I sat in my front yard and turned the sprinklers on and off a few times. Very rewarding.

I debated how to set up scheduling, but after more digging around, I stumbled into Mayank's extremly comprehensive [Homebridge Smart Irrigation](https://github.com/MTry/homebridge-smart-irrigation#readme) plugin. This one was a bit of a beast to configure, but it's worth it.  I can enable/disable watering days based on local watering restrictions, and leave the rest to the plugin which uses a HomeKit automation to trigger the virtual switch that turns the relay on and off. Based on the weather forecast and the capabilities of my system, it automatically runs the sprinkler for the "right" amount of time (and doesn't turn it on in the rain or before/after the rain).   

Part of getting this right was knowing the square footage covered by the system (enter: measuring tape), and the water volume the system spits out. Conveinently, the [Flume](http://flumewater.com) I have for catching leaks let me know that this thing burns 7.2Gallons/minute when on.  The end result is that on many days, the sprinkler runs for 4 to 11 minutes at around 6am, and my plants are a lot happier.

## Making the hardware pretty

Last up, this mess of wires was... messy.  I didn't take sufficient before photos to show how bad things get, but it wasn't pretty.

In my garage is a [Prusa MINI+ 3D printer](https://www.prusa3d.com/category/original-prusa-mini/) which behaves like an appliance. Put a STL file on a thumb drive, receive a print. I found a new case for the Rasberry Pi that is wall mountable: [Raspberry Pi 3 (B/B+), Pi 2 B, and Pi 1 B+ case with VESA mounts and more](https://www.thingiverse.com/thing:922740) and an "everything box" to put the relay and wire junctions into:  [Customizable everything box](https://www.thingiverse.com/thing:1680291).  Two hours later, these were ready to go and mounted on the wall.  Scroll back to the top for the finished product.

## Next steps

It probably makes sense to use something opensource to map HTTP requests on the Rasbperry Pi to control the relay, which would start automatically on boot, say something other than "Beep bo beep", etc, but it works as is! Next up is "Project Dollhouse" which is... significantly more involved. 

