NB!
---

This code is **highy outdated** and is left here for reference only.
Last update was in **2012**, lot of things has happened since.
If you'd like to update it or take care of it - write me, and I'll transfer ownership to you.

# Mina + Rails + Unicorn + nginx + God
======================================

An example deployment configuration using [Mina](https://github.com/nadarei/mina) for deployment.

Deploys and updates Rails application and config files for [Unicorn](http://unicorn.bogomips.org/), [nginx](http://wiki.nginx.org/Main), and [God](http://godrb.com/).

Why?
----

When I've started using Mina for deployment, these examples were what I needed most.

Not to just copy and use, but also to read and understand.

After a few days of tinkering I've come up with this setup.

So I thought, why not share? I hope it can be useful for somebody, so that one can see, learn, understand, and use.

How?
----

This example assumes the following:

* you're running Ubuntu in Vagrant locally (quite nice tool I'd say. Check out [RBates Railscast](http://railscasts.com/episodes/292-virtual-machines-with-vagrant) on this subject)
* you already have a user, that will be running deployment and all the server stuff
* this user have sudo privileges OR you have a separate user that have sudo privileges. You'll need sudoer for setup_extras and config:link tasks. If you don't have separate sudoer, script will assume that deployer have all the necessary sudo rights. If you know workaround, please, let me know about it!
* you already installed and configured git, rvm (global installation preferred) and nginx, at least
* probably something else I forgot at the moment. Don't expect flawless deploy from scratch anyway

Example deployment to local vagrant virtual machine:
```bash
# copy config/deploy.rb to $YOUR_APP/config/deploy.rb
# copy lib/mina to $YOUR_APP/lib
# edit common settings and anything you like in config/deploy.rb
# edit lib/mina/servers/*.rb to match your server configuration
mina init
mina setup          # Set up deploy server with paths, configs, etc. Requires sudo privileges or sudoer user
mina deploy
mina nginx:restart  # or nginx:start
mina god:start      # it will also run unicorn automagically
```
You should be up and running now. Yay!

All tasks by default will run for :default_server, which is :vagrant in this example. See config/deploy.rb lines 22 and 28-29
When you'll need to run the same for production, add `to=server_config_name`, like this:
```bash
mina init to=production
mina setup to=production
mina deploy to=production
mina nginx:restart to=production
mina god:start to=production
```

`mina deploy to=production` sounds just right. :) Thanks [@rstacruz](http://github.com/rstacruz) for the hint!
You can, of course, set the :default_server to anything you like.

`setup` task also invokes these additional tasks:
```bash
create_extra_paths
god:setup
god:upload
unicorn:upload
nginx:upload
```

and if you don't set separate sudoer user, these tasks invoked as well, implying that current user have sudo rights (if he doesn't, you'll be prompted to run 'sudo_setup' task, which does exactly that):

```bash
god:link
unicorn:link
nginx:setup
nginx:link
```

You can, of course, run them one by one. And you will eventually do so, if you find yourself in need of modifying some config files.

What now?
---------

You can check God status:

    mina god:status

...or overall processes' status/health:

    mina health

You can customize output of this command in lib/mina/extras.rb:33

**NB!** If you're running FreeBSD, do `set :term_mode, :exec` and after running Mina make sure you have no bash zombies, running around, eating your CPU. Just in case...

To deploy next release, just run

    mina deploy

If you've changed some of the config files for god/unicorn/nginx, you can upload them to server with `mina config:upload`.

If changed code includes unicorn or god control script (service), you will also need to run `mina config:link`, that requires sudo privileges. Keep in mind, that any nginx controlling task also requires sudo! Those are: stop, start, restart, reload, and status.

Individual tasks are also available, like `god:upload`, or `unicorn:link`.

You can as well run `mina god:parse:unicorn` to see how god's unicorn config file will look like without uploading it to server. Very useful for debugging!

Just check out task files under lib/mina directory, most of the code there is quite self-explanatory!
    
Man, this code sucks!
---------------------

Probably. But it is the code I'm currently using for production deployment, and if you think you can improve
it or just have a better idea regarding anything described here - send me an email or pull request.

Me
--

* [Blog](http://alfuken.tumblr.com/)
* [Twitter](http://twitter.com/alfuken)
* [Github](https://github.com/alfuken)
* [Github Page](http://alfuken.github.com/mina-rails-unicorn-nginx-god/)
