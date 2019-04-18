# lytedev-hugo-theme

> The Hugo theme for my personal site at https://lytedev.io

![Index page][index-screenshot]
![About page][about-screenshot]

## Building the Theme

Due to the odd requirements I have for my personal site, there is a surprisingly
flexible build system for what seems to be a very simple website. Regardless, to
use this theme, you will need to build the actual theme files that Hugo can grok
before the theme can actually be used with Hugo.

``` sh
yarn # or `npm install`
yarn run build # or `npm run build`
```

If you're modifying the theme and would like some reload-as-you-dev goodness,
just do `yarn run dev` instead.

## Using with Hugo

Add the theme as a git submodule to your Hugo site:

``` sh
git submodule add https://github.com/lytedev/lytedev-hugo-theme themes/lytedev
```

Then build the theme (see above).

Finally, edit your Hugo config to use the theme:

``` yaml
theme: "lytedev"
```

## Usage and Options

Here are a few theme-specific things you may want to mess with to get it working
with your site.

* Add your logo! The theme will look for a `logo.html` in your
  `layouts/partials` and display it in the theme location, otherwise, the site
  title will just be displayed.
* Set a hero image to display on the index page! Just set `params.index.image`
  in your Hugo site config. You can also set `params.index.imageOverlayColor`
  and `params.index.imageOverlayOpacity` to "encourage" the image to be darker
  so your intro text is still highly legible.
	
---


[index-screenshot]: /meta/screenshots/index-hero.png
[about-screenshot]: /meta/screenshots/about.png
