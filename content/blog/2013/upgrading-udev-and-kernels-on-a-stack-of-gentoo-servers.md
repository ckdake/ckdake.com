---
title: Upgrading udev and kernels on a stack of Gentoo servers
created_at: 2013-02-07 21:07:55 -0500
kind: article
---
TL;DR: Install linux-firmware and uninstall pecl-apc. scroll down for a graph that shows why.

<h3>The Plan</h3>

The backlog of new packages to install was big enough that it was time for me to bite the bullet and upgrade the kernel and udev on all of my Gentoo servers for ithought.org They were a mix of 2.6.*/3* kernels and old unsupported udev.

I documented all the hardware, wrote out compilation plans for kernels for all of them including all the Gentoo, hardware, and software specific configuration options and built new kernels. 3.6.11 for the amd64 boxes and 3.5.7 for the x86 ones. Userland things upgraded successfully, and things were good to go for rebooting.

Just to play it safe (and to replace a server belonging to one of my colocaiton customers) I scheduled some routine maintenance to reboot all of the servers for 9pm on Wednesday February 6th.

<h3>The Not So Great Reboot</h3>

Rebooting the servers had mixed results. Several needed their root volume in grub.conf updated due to kernel changes in the way that volume names are presented, and I left out a few things that required booting with a boot cd to fix (software raid support on an old amd64 scsi box, and the Fusion MPT SAS driver on the box connected to the Dell MD1000 storage system) and thought I was in the clear, with just a few minutes of downtime for each server. Everything went as planned.

However, the x86/2.5.7 boxes had a problem. None of them could connect to the Internet because they couldn't see their eth* devices.  This thread is a similar debugging experience to mine:  <a href="http://forums.gentoo.org/viewtopic-t-948718-start-25.html">http://forums.gentoo.org/viewtopic-t-948718-start-25.html</a>.  It seemed to be a problem with udev, which was a big problem because due to the new kernels combined with the age of all the other software and what was available in portage, I didn't have many options.

The newest server was new enough that I could use package.mask to rollback to an older udev that worked with the kernel on that system (2.6.36) but the other servers had kernels so old that they didn't work with the oldest versions of udev available in portage, which meant no downgrade was available.

This troubleshooting lasted from around 9:30pm until past 1:30am in the morning, trying kernel reconfiguration, customizing udev's rule files. With some help from a few people in irc.freenode.net#lugatgt that know far more about udev than I, we confirmed that everything in my kernel and udev setups looked correct.  All net device starting yielded a 'SIOCADDRT no such process' that was not helpful to any of us for debugging, but a conviently timed glance at the output of `dmesg` yielded the problem, a missing file that is part of the 'linux-firmware' package.  I installed linux-firmware via a USB drive on the broken servers, rebooted, and everything was finally working again. Success!  

Nagios alarms all cleared, sites were back up, and I headed home to sleep.

<h3>The Next Battle</h3>

I woke up early to check on things, and one of the servers was down. The graphs indicated a combination of massive iowait processes and RAM utilization, but no swap usage. Interesting.

A few hours later, a stop by #lugatgt and asking some knowledgable coworkers, and I'd gotten acquainted with `iotop`, `iostat`, and others.  I'd moved the MySQL datadirectory between RAID devices which only made things worse (and was undone), and narrowed things down to 6-12Mbps of write IO to the / volume. This was very strange because everything in /var (mysql, apache, vhost roots, logs, etc) are all on a separate RAID volume on a separate RAID controller.

The only file marked as open for writing in the php-cgi process's using 99.99% of their time waiting on IO were in /var/log, but no log files were growing, and disk utilization wasn't climbing. This indicated writing to unattached inodes, and it turned out that there is some conflict with the way APC (the opcode cache for php) was configured to use shm (shared memory in kernel land).  I disabled apc, bounced apache, and the high-write load on / disappeared and conditions improved.

The impact of disabling APC is that PHP has to do a little more work on each http request which slightly lowers http respons times. It has doubled 'user' CPU load from ~15% to ~30% of one CPU, but has lowered the iowait from tanking the system after this update.  That said, pre-update iowait hovered around ~50% and it is now down to ~5% which has some nice performance impacts for the rest of the system and may serve to actually decrease average response time. 

It's frustrating when tools that are designed to enhance performance cause things to implode, but it's nice to clean up the stack a little and APC doesn't have the reputation of being the most stable thing out there anyways. Time will tell what impact this has on response code breakdown.  Here's graph of CPU usage on this box during the events in the last 24 hours. From descriptions above you can probably see what looks pretty clear in hindsight.

<img src="//ckdake.com/files/cpu.png" />

<h3>The End</h3>

One more server needs a reboot with the newest kernel and udev userland, but given what I know now I'm confident that it will go well (almost confident enough to do remotely). 

If you're a hosting customer of mine or a user of one of the sites that I host, I apologize for the extended outage last night and the slowness this morning as I worked out the IO issues, but know that these upgrades include security updates and having consistently configured systems makes testing out upgrades like this possible in the future. I'm on a monthly rotation now for software updates, and everything can now be tested on a backup server before applying it to any of the primary servers. Thanks for your business!