---
title: Wordpress and fail2ban with Apache
created_at: 2014-08-04 18:40:37 -0400
kind: article
---

Hackers suck. As a web hosting provider with 40+ people running Wordpress that don't always keep it up to date, hackers are always trying to get in. Last month they were pretty successful, so I tightened some things down a little bit further. I don't  manage any of the PHP files, so coordinating things among customers is a lot harder than it could be, and I won't be able to get them to standardize on plugins (e.g. a way to log failed logins to a consistent place).

<!-- more -->

First up was trying to get everyone upgraded to the newest version which keeps most of the automated tools out, but still leaves everyone exposed to brute-force password guessing attempts.

One can go the route of configuring Wordpress plugins to handle everything, but because I use [fail2ban](http://www.fail2ban.org) to protect SSH access I figured it wouldn't be too bad to get some help there. Turns out, I was right!

I added two new jails, one for wp-login.php requests and one for xmlrpc.php requests:

<pre><code class="language-php">
[wordpress-xmlrpc]

enabled  = true
filter   = wordpress-xmlrpc
action   = iptables[name=WordPressXMLRPC, port=http, protocol=tcp]
logpath  = /var/log/apache2/access_log
maxretry = 5

[wordpress-login]

enabled  = true
filter   = wordpress-login
action   = iptables[name=WordPressLogin, port=http, protocol=tcp]
logpath  = /var/log/apache2/access_log
maxretry = 5
</code></pre>

And the filter.d files to go along with it:

<pre><code class="language-php">
# wordpress-login.conf
[INCLUDES]
before = common.conf

[Definition]
_daemon = wordpress
failregex = ^[a-zA-Z0-9\.]+ &lt;HOST&gt; .*POST.*/wp-login\.php HTTP.*
ignoreregex =
</code></pre>

<pre><code class="language-php">
# wordpress-xmlrpc.conf
[INCLUDES]
before = common.conf

[Definition]
_daemon = wordpress
failregex = ^[a-zA-Z0-9\.]+ &lt;HOST&gt; .*/xmlrpc\.php.*
ignoreregex =
</code></pre>

Are these a little overkill? Definitely. From my global config for limits, if someone POSTS to wp-login.php 5 times in a 10 minute period, they get firewalled off for a day. If they hit xmlrpc.php 5 times in a 10 minute period, they get firewalled off for a day.

That said, I don't image any regular usage from anyone will run into these limits. If they do, my hosting customers know how to contact me. After ~3 hours of running this, hackers are getting slowed down already:

<pre><code class="language-php">
Chain fail2ban-WordPressLogin (1 references)
target     prot opt source               destination
REJECT     all  --  202.177.25.123       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  177.70.21.29         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  212.82.217.9         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  141.105.66.179       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  88.190.45.37         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  216.222.148.52       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  80.97.64.148         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  94.23.28.193         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  91.123.193.54        0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  193.109.248.66       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  108.162.216.31       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  50.22.232.106        0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  37.98.197.5          0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  117.18.73.66         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  108.163.165.66       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  95.163.121.138       0.0.0.0/0            reject-with icmp-port-unreachable
RETURN     all  --  0.0.0.0/0            0.0.0.0/0

Chain fail2ban-WordPressXMLRPC (1 references)
target     prot opt source               destination
REJECT     all  --  155.109.35.51        0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  89.248.168.164       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  117.18.73.66         0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  173.245.62.107       0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  198.204.243.115      0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  80.82.78.57          0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  93.174.93.204        0.0.0.0/0            reject-with icmp-port-unreachable
REJECT     all  --  89.248.174.101       0.0.0.0/0            reject-with icmp-port-unreachable
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
</code></pre>

Some gotchas specific to my setup:

* I didn't have multiport support for iptables rules compiled into my kernel which when using iptables-multi in jails.conf gave the cryptic error message on restarting iptables: "iptables: No chain/target/match by that name."  I'm fine with just blocking http.
* I use multiple vhosts going to the same log file with a standard, but less common log format. This meant adding the "[a-zA-Z0-9\.]+"" regex before the HOST named capture so that the request vhost wasn't used for blocking. Hint: Use the "fail2ban-regex" tool to test out rules on a log file!
* Make sure your actions have separate names. When you name them the same thing, you won't get what you are expecting.
