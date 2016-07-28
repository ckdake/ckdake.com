---
title: Certbot and Cloudflare
created_at: 2016-07-27 20:58:26 -0400
kind: article
---

If you're like me, you host a bunch of PHP+MySQL websites using apache, you have CloudFlare in front of most of them, and you think SSL Everywhere is a pretty good idea.  You set up letsencrypt, they renamed it to certbot, and SSL is on everywhere and nice. You've also realized that after following the certbot defaults, certbot needs to connect with `openssl s_client` to make sure things are working right, so you have to pause CloudFlare to successfully renew certs. You've also realized this means your automated renew-all-the-certs cron job is not going to work. Oops. Your certs expire tomorrow too.

Had you used one of the other methods (e.g. docroot verification) you'd be ok, but you would have more manual steps for each site you add. Not the best.

Do not fear! There is a not-ideal-but-works-pretty-well way of doing this. My specific version doesn't have the best error handling , has no tests, and may be a jerk, but it's worked for me for the last round of renewals so it's got that going for it. Read on for details.

## The Assumptions

1. You have certbot up and running and working and your sites have SSL certificates. You just need to renew them. (This may work for setup, but I usually do that before setting up CloudFlare)
2. Renewal works when CloudFlare is paused (e.g. your are bypassing their SSL man-in-the-middle attack and connecting straight to your server)
3. Your certbot is a old letsencrypt that you've upgraded. If you started with certbot, you'll just need to change some paths I bet.
4. You can run `apt-get jq` or otherwise install `jq` on your system somewhere where you can use it. Gotta turn the CloudFlare API's JSON into something bash-friendly.

## The Setup

I've put a handful of scripts in /root/cloudflare_tools. They connect to the CloudFlare API, pause your domains, run renew, and then unpause them. Success!  The "preflight" script runs before each domain so you'll get everything paused a bunch of times, and the "postflight" script runs after your last renewal finishes so everything will be paused until all the renewals finish, but they don't seem to take too long so I think this is okay. I did not put these in a git repo for you to clone because you should read all of them, adjust paths/etc, and not just blindly run things like this. Your CloudFlare api keys are pretty secret stuff.

First up, store some credentials in /root/.cloudflare

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=.cloudflare"></script>

Then you'll want this one in /root/cloudflare_tools/domains_to_renew.sh to get all the domains certbot is managing. We only need to pause once per domain even if there are multiple subdomain certs, so this makes sure each domain name just appears once.

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=domains_to_renew.sh"></script>

Then over to /root/cloudflare_tools/pause_domain.sh to pause a single domain via the CloudFlare api:

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=pause_domain.sh"></script>

And a script to pause ALL the things in /root/cloudflare_tools/pause_all_domains.sh:

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=pause_all_domains.sh"></script>

Once those run, you'll be paused and certbot can do it's then. Then to unpause a single domain in /root/cloudflare_tools/unpause_domain.sh:

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=unpause_domain.sh"></script>

And a script to unpause ALL the things in /root/cloudflare_tools/unpause_all_domains.sh:

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=unpause_all_domains.sh"></script>

With that, you should be all set! Make sure that when you run pause_all_domains.sh and unpause_all_domains.sh they do what you expect.

Lastly, set up your auto-renew cron:

<script src="https://gist.github.com/ckdake/6b199473065d48190e45ea216b566952.js?file=certbot.cron"></script>

And wait for the email next Monday morning to let you know how the renewal attempt went. Let me know how this works for you!
