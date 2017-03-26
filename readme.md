# lytedev

> My personal blog/portfolio/site generated with Hugo.

## Setup

* Setup [Hugo][hugo]:
	`export GOPATH="$HOME/go" && go get -v github.com/spf13/hugo`

* Pull down this repository:
	`git clone https://github.com/lytedev/lytedev.github.io.git`

* Pull down the theme:
	`git clone https://github.com/lytedev/lytedev-hugo-theme.git themes/lytedev`

* Or if you want the theme in another directory and symlinked in:
	`git clone https://github.com/lytedev/lytedev-hugo-theme.git ../lytedev-hugo-theme && ln -s "$PWD"/../lytedev-hugo-theme "$PWD"/themes/lytedev`

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
