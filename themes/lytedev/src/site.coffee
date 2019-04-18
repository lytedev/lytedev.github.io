document.documentElement.classList.remove 'no-js'

# simple wrapper for console.log
log = ->
	if not console? then return false
	args = [].slice.apply arguments
	console.log.apply console, args

log 'Thanks for checking out my site\'s theme\'s code!'
log 'The raw source is available on my GitHub at https://github.com/lytedev'

easeOutCubic = (t) -> (--t) * t * t + 1

animateValueOverTime =
	(initialValue, endValue, duration, callback, easeFunc) ->
		# duration is in ms
		# if we don't have requestAnimationFrame, just instantly set the value
		if not requestAnimationFrame? then return obj[key] = endValue
		if not easeFunc? then easeFunc = (time) -> time

		diff = parseFloat(endValue) - parseFloat(initialValue)
		initialTime = 0
		elapsed = 0

		update = (elapsed) ->
			if initialTime == 0
				initialTime = elapsed

			else
				if elapsed - initialTime >= duration
					return callback endValue
				else
					callback initialValue +
						(easeFunc(parseFloat((elapsed - initialTime) / duration)) * diff)

			requestAnimationFrame update

		requestAnimationFrame update

animateScrollToElement = (el) ->
	scrollTo = el.offsetTop
	top = (window.pageYOffset or document.scrollTop) -
		(document.clientTop or 0) or 0
	scroll = (val) ->
		window.scroll(0, val)
	animateValueOverTime top, scrollTo, 500, scroll, easeOutCubic

do -> # setup scroll-to-content buttons
	scrollToMainElements = document.getElementsByClassName 'scroll-to-main'
	main = document.getElementById 'site-content'
	for el in scrollToMainElements
		el.addEventListener 'click', -> animateScrollToElement main
