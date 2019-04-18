# lytedev

> My personal blog/portfolio/site generated with Hugo.

**Note**: This repository's `master` branch contains the built static pages. If
you're wanting the Hugo-compatible files in order to build the site, you want
the `source`  branch.

## Setup

* Setup [Go][go-setup]

* Setup [Hugo][hugo]:
	`go get -v github.com/spf13/hugo`

* Pull down this repository:
	`git clone https://github.com/lytedev/lytedev.github.io.git`

* Pull down dependencies:
	`pushd themes/lytedev && yarn && popd && yarn`

* Build the theme and our files:
	`yarn run build-all`

* Or (if we're developing) serve it up and rebuild everything as files changed:
	`yarn run dev` (visit [http://localhost:1313][localdev])

* The site can be deployed via the `deploy.coffee` script. You can run it with:
	`yarn run deploy`

See `package.json` for other build/watch combinations and options.

---


[hugo]: https://gohugo.io
[localdev]: http://localhost:1313
[go-setup]: https://golang.org/doc/install
