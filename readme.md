# lytedev

> My personal blog/portfolio/site generated with Hugo.

## Setup

* Setup [Hugo][hugo]:
	`export GOPATH="$HOME/go" && go get -v github.com/spf13/hugo`

* Clone the theme to `themes/lytedev`:
	`git clone https://github.com/lytedev/lytedev-hugo-theme.git themes/lytedev`

* Pull down dependencies:
	`pushd themes/lytedev && yarn && popd && yarn`

* Build the theme and our files:
	`yarn run build-all`

* Or (if we're developing) watch and rebuild everything as needed:
	`yarn run watch-all`

See `package.json` for other build/watch combinations and options.

---

[hugo]: https://gohugo.io
