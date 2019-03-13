---
image: "/img/code-mirror.jpg"
date: "2019-03-13T08:37:34-05:00"
imageOverlayColor: "#000"
imageOverlayOpacity: 0.7
heroBackgroundColor: "#333"
description: For those of us who want to self-host and display their work in a "socially expectable" manner.
title: Mirroring Gitea to Other Repository Management Services
draft: true
---

I have a [Gitea][gitea] instance I self-host at home. I keep most of my
repositories there, but I recognize that most other developers and potential
employers will want to see [my work *on* GitHub][me-on-github].

<!--more-->

# TL;DR

+ Setup an SSH key for your Gitea instance on the relevant external repositories
+ Leverage `post-receive` git hooks in Gitea to push changes to the relevant
		external repositories while identifying with your new SSH key

Also, most of the magic is [here](#post-receive-script).

# Mirroring

In order to achieve this with minimal effort, I was going to need to utilize
mirroring. Mirroring is a popular git concept that allow a repository to
effectively exist in multiple places at once, though generally mirrors are
read-only.

Mirroring isn't exactly a specific procedure or command, it's simply the act of
reflecting all (or some specific subset) of commits that exist elsewhere,
generally in an automated fashion. Forks might be considered "mirrors" of
a repository at a given point in time.

GitLab, for example, [supports mirroring pretty seamlessly][0]. Gitea, however,
is pretty minimal, which is one of its perks to me. That does not, however, mean
that it is lacking in features.

Gitea supports a few [git hooks][1], which are a simple way to run a script when
something happens. As far as a repository manager is concerned, the only real
hooks that matter are the following (which Gitea supports):

+ `pre-receive`: Runs when a client pushes code to the repository. You can use
		this to prevent, for example, code that fails linters, doesn't pass tests,
		or even that can't be merged using a specific merge strategy.
+ `update`: Runs for each branch being updated when a client pushes code to the
		repository. This is similar to pre-receive, but allows for more fine-grained
		control. Maybe you want to only make the previous restrictions on your
		`master` branch. This would be the way to do it.
+ `post-receive`: Runs after your `pre-receive` and `update` hooks have finished
		when a client pushes code to the repository. This is what we'll be
		leveraging to push code downstream!

With that lengthy introduction, let's dive in!

# Setup

Alrighty, this has a few simple steps, so let's outline what we need to do
first:

1. Setup SSH keys for Gitea and your other repository management services
	1. Generate fresh keys (`ssh-keygen -f gitea` will generate a private key in
		 the `gitea` file and a public key in the `gitea.pub` file)
	2. Add the public key (`gitea.pub`) to your "mirrors-to-be" repositories *with
		 write access*
	+ **Note**: I recommend at the very least to create one Gitea key and add it
		to the individual repositories, though individual keys for each repository
		is tighter security in case your Gitea instance becomes compromised
	+ **Note**: Your "mirrors-to-be" repositories must be blank or have related
		histories!
2. Setup the `post-receive` hook on your Gitea repository to push using the
 	newly generated private key to the mirror(s)

I'm not going to explain much on how to add Deploy Keys for the various
repository management systems out there, so here's a link [explaining the process
for GitHub][2].

# Hookin' Around

Now we're all set for the magic! Also, for reference and sanity, I'm running
Gitea in Docker on an Arch Linux server with the following version (but this
should work pretty much regardless):

+ Gitea Version: `3b612ce built with go1.11.5 : bindata, sqlite,
		sqlite_unlock_notify`
+ Git Version: `2.18.1`

Let's go ahead and open up our Gitea repository's index page.

![My dotfiles repository index](/img/scrots/gitea-mirroring/repo-index.png)

And head to the repository's "Settings" tab... (oh yes, you'll need to have the proper permissions on
the repository itself!)

![Click the "Settings" tab in the
top-right](/img/scrots/gitea-mirroring/repo-index-hl-settings.png)

And now to the "Git Hooks" tab...

![Click the "Git Hooks"
tab](/img/scrots/gitea-mirroring/repo-settings-hl-git-hooks.png)

Let's edit the "Post Receive" hook...

![Edit the "Post Receieve"
hook](/img/scrots/gitea-mirroring/repo-hooks-hl-post-receive-edit.png)

And you will be presented with a form where you can put any kind of script you
want! Remember the SSH keys you generated so long ago? We're going to need the
contents of the private key now. Here are the script contents you're going to
use, replacing the variables as necessary.

## Post-Receive Script

```bash
#!/usr/bin/env bash

downstream_repo="git@github.com:lytedev/dotfiles.git"
# if tmp worries you, put it somewhere else!
pkfile="/tmp/gitea_dotfiles_to_github_dotfiles_id_rsa"

if [ ! -e "$pkfile" ]; then # unindented block for heredoc's sake
cat > "$pkfile" << PRIVATEKEY
# ==> REMOVE THIS ENTIRE LINE & PASTE YOUR PRIVATE KEY HERE <==
PRIVATEKEY
fi

chmod 400 "$pkfile"
export GIT_SSH_COMMAND="ssh -oStrictHostKeyChecking=no -i \"$pkfile\""
# if you want strict host key checking, just add the host to the known_hosts for
# your Gitea server/user beforehand
git push --mirror "$downstream_repo"
```

Click "Update Hook" and you're all set! Now just push to the repo and watch it
magically become mirrored to the downstream repository!

[me-on-github]: https://github.com/lytedev
[gitea]: https://gitea.io/en-us/
[0]: https://docs.gitlab.com/ee/workflow/repository_mirroring.html
[1]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
[2]: https://developer.github.com/v3/guides/managing-deploy-keys/#deploy-keys
