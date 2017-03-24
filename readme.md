# lytedev

> My personal blog/portfolio/site generated with Hugo.

## Setup

* Setup [Hugo][hugo]:
	`export GOPATH="$HOME/go" && go get -v github.com/spf13/hugo`

* Pull down this repository (and it's submodules, which contains the theme):
	`git clone --recursive https://github.com/lytedev/lytedev.github.io.git`

* Or if you just want the theme submodule after cloning this repository:
	`git submodule update --init --recursive`

* Or still if you just want the theme in another directory and symlinked in:
	`git clone https://github.com/lytedev/lytedev-hugo-theme.git ../lytedev-hugo-theme && ln -s "$PWD"/../lytedev-hugo-theme "$PWD"/themes/lytedev`

* Pull down dependencies:
	`pushd themes/lytedev && yarn && popd && yarn`

* Build the theme and our files:
	`yarn run build-all`

* Or (if we're developing) serve it up and rebuild everything as files are
	updated: `yarn run dev` (visit [http://localhost:1313][localdev])

* The site can be deployed via the `deploy.coffee` script. You can run it with:
	`yarn run deploy`

See `package.json` for other build/watch combinations and options.

---


[hugo]: https://gohugo.io
[localdev]: http://localhost:1313
