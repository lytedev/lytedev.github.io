---
image: "/img/locks.jpg"
date: "2019-03-07T10:17:30-06:00"
imageOverlayColor: "#000"
imageOverlayOpacity: 0.8
heroBackgroundColor: "#000"
description: "Use an amazing terminal client with an amazing Chat framework!"
title: Weechat & Matrix Encryption Guide
draft: false
---

There's a new-fangled [Python WeeChat plugin][weechat-matrix] that supports
end-to-end encryption. This guide will walk you through what is currently
a semi-annoying setup, as the entire project is still under heavy development.

<!--more-->

# TL;DR

Run `git clone
https://git.faceless.lytedev.io/lytedev/weechat-matrix-encryption-guide.git
/tmp/wmeg && /tmp/wmeg/easy-script.bash` and skip to the end.

## Python Versions

We need to establish which version of Python your WeeChat is using. You can find
this out in WeeChat with `/python version`. In my case, my `python` binary is
3.7.2 (`python -V`) while my WeeChat Python version is 2.7.15.

## Dependencies

There are a number of dependencies we can go ahead and start grabbing. The main
repository lists a number of them in the `README`, so we will grab those. We
also need to install `libolm` however you would do that for your environment.

```
sudo pip2 install pyOpenSSL typing webcolors future atomicwrites attrs logbook pygments
pacaur -S libolm # or for Ubuntu (and maybe Debian?): sudo apt-get install libolm-dev
```

Notice that we left out the [`matrix-nio`][matrix-nio] dependency. It's not in
PyPi, so we can't just `pip2 install matrix-nio` (yet!) and PyPi's `nio` package
is something probably unrelated, so we'll need to install it manually.

## `matrix-nio`

Let's go ahead and clone down the repository and get ready to do some stuff:

```
git clone https://github.com/poljar/matrix-nio.git
cd matrix-nio
```

If you're looking around, documentation seems a bit sparse on how to do this,
but it has a mostly normal manual Python package installation workflow.

First, lets grab all the dependencies specific to the `matrix-nio` package:

```
sudo pip2 install -r ./rtd-requirements.txt
```

And now we expect to be able to install it:

```
sudo python2 ./setup.py install
```

But you'll see the install script pauses for a second before we get an odd
error:

```
Processing dependencies for matrix-nio==0.1
Searching for python-olm@ git+https://github.com/poljar/python-olm.git@master#egg=python-olm-0
Reading https://pypi.org/simple/python-olm/
Couldn't find index page for 'python-olm' (maybe misspelled?)
Scanning index of all packages (this may take a while)
Reading https://pypi.org/simple/
No local packages or working download links found for python-olm@ git+https://github.com/poljar/python-olm.git@master#egg=python-olm-0
error: Could not find suitable distribution for Requirement.parse('python-olm@ git+https://github.com/poljar/python-olm.git@master#egg=python-olm-0')
```

Out of the box, Python packages' `setup.py` scripts seem to not know how to
handle packages whose URL specifies to grab it via VCS, such as `git+`. So we'll
just help it out and grab it ourselves (instead of tinkering with anybody's
scripts):

```
sudo pip2 install -e git+https://github.com/poljar/python-olm.git@master#egg=python-olm-0
```

*Now* we should have everything we need to install the `matrix-nio` Python
package:

```
sudo python2 ./setup.py install
```

## Weechat Plugin Installation

Once we've done that, we should have all the dependencies for `weechat-matrix`,
so let's go ahead and clone that and install it!

```
git clone https://github.com/poljar/weechat-matrix.git
cd weechat-matrix
make install
```

Done!

## Configuration

The rest is up to you! You'll need to [configure your Matrix servers within
WeeChat][weechat-matrix-config] and then verify keys. Verifying keys isn't
a particularly clean process at the moment, but I expect it shall improve.  For
now, I followed this basic process in WeeChat:

+ Open a split at your status window so you can see it and the encrypted channel
	at the same time. (`/window splitv`)
+ Open the encrypted channel whose keys you need to verify.
+ List the unverified keys in the current channel. (`/olm info unverified`)
+ For each user with keys listed there, verify all of their listed keys via your
	preferred method. Alternatively, you can do this on a per-device basis. See
	`/help olm` for details.
+ Once all keys are verified, tell WeeChat you have done so. (`/olm verify
	@username:homeserver.example.com`)
+ Repeat until there are no unverified keys remaining in the current channel and
	repeat for each channel. Whew!


[weechat-matrix]: https://github.com/poljar/weechat-matrix
[weechat-matrix-config]: https://github.com/poljar/weechat-matrix#Configuration
[matrix-nio]: https://github.com/poljar/matrix-nio

