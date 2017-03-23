---
date: 2017-02-22T14:43:02-06:00
image: https://images.unsplash.com/photo-1473186505569-9c61870c11f9?dpr=1&auto=format&fit=crop&w=1500&h=1000&q=80&cs=tinysrgb&crop=
imageOverlayColor: "#000"
imageOverlayOpacity: 0.7
heroBackgroundColor: "#333"
title: Contact
description: "Need to get in touch?"
---

<div class="text-center">
	<form action="https://formspree.io/daniel@lytedev.io" method="POST">
		<div class="field">
			<label name="name">Full Name</label>
			<input type="text" name="name" placeholder="Daniel Flanagan" />
		</div>
		<div class="field">
			<label name="_replyto">Email</label>
			<input type="email" name="_replyto" placeholder="you@gmail.com" />
		</div>
		<div class="field">
			<label name="content">Message</label>
			<textarea name="content" rows="4"></textarea>
		</div>
		<div class="field">
			<input class="button primary" type="submit" value="Send" />
		</div>
    <input type="hidden" name="_next" value="/thanks" />
    <input type="hidden" name="_subject" value="Contact Form Submission - lytedev" />
	</form>
	<small>
		<p>
			Email form not working for you? Just email me: <a href="mailto:daniel@lytedev.io">daniel@lytedev.io</a>
		</p>
	</small>
</div>
