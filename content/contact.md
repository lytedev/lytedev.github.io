---
date: 2017-02-22T14:43:02-06:00
image: /img/pen-journal.jpg
imageOverlayColor: "#000"
imageOverlayOpacity: 0.7
heroBackgroundColor: "#333"
title: Contact
description: "Need to get in touch?"
---

<div class="text-center">
	<p>
		Email me at <a href="mailto:daniel@lyte.dev">daniel@lyte.dev</a> or use
		the form below.
	</p>
	<form action="https://formspree.io/daniel@lyte.dev" method="POST">
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
</div>
