---
image: "/img/dried-lava.jpg"
date: "2019-03-20T20:24:54-05:00"
imageOverlayColor: "#000"
imageOverlayOpacity: 0.5
heroBackgroundColor: "#333"
description: "If you're using Elm, you're probably dealing with forms and
fields. Here's how I did!"
title: "Elm: Forms, Fields, and Abstractions"
draft: true
---

If you're using Elm, you're probably dealing with forms and fields. You're also
probably wanting to do functional programming "right" and compose smaller
functions together.

<!--more-->

# TL;DR

+ Functions! [Scroll to the bottom](#full-source) for the full code!

## How Did I Get Here?

To preface this, I'm going to be writing a *lot* of forms with a *lot* of
fields, all of which will pretty much work exactly the same, so creating a layer
of abstraction to boost my productivity down the line is going to be massively
important when it comes to changing things.

You may have even found or been told to use [this library][1]. If you're really
nuts, you may have even tried to use it before finding out that as soon as you
want to change the default renderings at all, you are [encouraged][2] to [copy
and paste this 700+ line file][3] and tweak accordingly, all the while being
told it's not really a big deal.

As you can tell, I feel very strongly that this is stupid. You'll have to
forgive my ranting. Sure, technically it's "composable", but as soon as
a library or module isn't easily doing what I need it to do, instead of copying
code from it, I'm just going to roll my own, which is generally a really good
way to learn something anyways. So, while frustrated, I was also eager to tackle
the problem.

Since the Elm compiler is so awesome, I've taken to what I'm calling
"compiler-driven development", which is where I write out what I expect to work
and then proceed to make it work.

As a simple test, I know I'm going to need fields that let a user input currency
and percentages. I know that the only real differences that need to be
abstracted away will be the type (currency, percentage, etc.), the getter they
can use to display their current value from my `Model`, and the `Msg`
constructor they will use to update that `Model` as the user fires `input`
events. There will also be tooltips, validation, and other such things, but for
the sake of simplicity, let's focus on these. So, my code will look something
like the following:

```elm
type alias Model =
	{ amount : String
	, ratePercent : String
	}

type Msg
	= UpdateAmount String (Cmd Msg)
	| UpdateRatePercent String (Cmd Msg)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
	case msg of
		UpdateAmount s c -> ( { model | amount = s }, c )
		UpdateRatePercent s c -> ( { model | ratePercent = s }, c )

view : Model -> Html Msg
view model =
	form model
		-- fieldFunc "label" getter MsgConstructor
		[ currencyField "Amount" .amount UpdateAmount
		, precentField "Rate" .ratePercent, UpdateRatePercent
		]
```

I want this code to handle rendering my fields, formatting and un-formatting the
text input's value (more on this later), and firing update `Msg`s accordingly.
So we just need to implement the `form` function and the `currencyField` and
`percentField` functions.

Note that I'm storing my values as a string in this case, even though my intent
is for them to be numbers. I'm sure there is a cool Elm way to handle this using
the type system, but I haven't got that far and for the moment I'm just
extracting the value from them whenever the calculations need to be done. If and
when that changes, perhaps I can make that another blog post!

Let's start with form, since it should be the simplest.

```elm
type alias Fields model msg =
    List (model -> Html msg)

form : model -> Fields model msg -> Html msg
form model fields =
	Html.form []
		(List.map (\f -> f model) fields)
```

So we've got a type alias for our fields, which is a list of things that are
really just like our view: take a model, return some html. Then all the `form`
function does is create an `Html.form` whose children are just the result of
mapping over the fields list, calling those "view-like" functions, passing the
model. Easy. Now your form function may need stuff like submit buttons or other
actions, but mine does not. Again, do what is necessary for *your* application!

Now, with some forward thinking, I know both my `currencyField` and
`percentField` are going to do similar things with minor differences. Let's talk
about those for a moment.

My inputs need to show human-friendly values while idle, but once they're
focused, they should show a more "raw" value so that editing the numerical
values is easy and the user doesn't need to manage commas, units, or anything
else; they just enter a number and the app will show them a nicely-formatted
version of it. Most high-tech spreadsheets work similarly. I'll use `onFocus`
and `onBlur` events to accomplish this.

So let's do some more "compiler-driven development" (this will get a little
nuts):

```elm
currencyField : String -> (model -> String) -> (String -> Cmd msg -> msg) -> model -> Html msg
currencyField label getter updateMsg model =
	formattedNumberField label (\m -> m |> getter |> currencyFloat) getter updateMsg model

percentField : String -> (model -> String) -> (String -> Cmd msg -> msg) -> model -> Html msg
percentField label getter updateMsg model =
	formattedNumberField label (\m -> m |> getter |> percentFloat) getter updateMsg model
```

Whew! Again, I bet there's a type pattern-matchy way to clean this up even more.
These functions take the following arguments:

1. The field's label
2. A getter, which, given a model, can provide the text that the input should
	 display
3. A `Msg` constructor that takes a `String` (which is passed from `onInput`)
	 and a `Cmd msg`, since in some cases we might wanna do that, but I won't get
	 into that here
4. The model

Okay! That all makes sense. Now what's up with `formattedNumberField`? That's
the next layer of the abstraction onion I'm building up. It's for any number
field that needs to unformat `onFocus` and reformat `onBlur`. Also, we'll need
to define `currencyFloat` and `percentFloat`. This will mean a fair bit of code
to handle converting `String` to `Float` and back for our formatting and
unformatting.

So how is *all that* gonna work, you ask? With more abstraction onion layers:

```elm
type alias FieldConfig t model msg =
    { label : String
    , value : model -> String
    , onInput : t -> msg
    , onFocus : model -> msg
    , onBlur : model -> msg
    }

formattedNumberField : String -> (model -> String) -> (model -> String) -> (String -> Cmd msg -> msg) -> model -> Html msg
formattedNumberField label formatter getter updateMsg model =
	numberField
		-- FieldConfig
		{ label = label
		, value = getter
		, onInput = \s -> updateMsg s Cmd.none
		, onFocus = \m -> updateMsg (m |> getter |> unFormat) (Select.elementId label)
		, onBlur = \m -> updateMsg (formatter m) Cmd.none
		}
		model

floatSplit : Float -> ( String, String )
floatSplit f =
	case f |> String.fromFloat |> String.split "." of
		[ a, b ] ->
			( a, b )

		[ a ] ->
			( a, "0" )

		_ ->
			( "0", "0" )

niceFloatSplit : Float -> ( String, String )
niceFloatSplit f =
	let
		( n, mantissa ) =
			floatSplit f
	in
	( n |> chunksOfRight 3 |> String.join ",", mantissa )

-- rounded to the hundredths (cents)
currencyFloat : Float -> String
currencyFloat f =
	let
		( n, mantissa ) =
			niceFloatSplit (String.toFloat (round (f * 100)) / 100)
	in
	"$" ++ n ++ "." ++ String.left 2 (String.padRight 2 '0' mantissa)

-- rounded to the hundredths
percentFloat : Float -> String
percentFloat f =
	let
		( n, mantissa ) =
			niceFloatSplit f
	in
	n ++ "." ++ String.left 2 (String.padRight 2 '0' mantissa) ++ "%"
```

Now we've introduced a whole bunch of nonsense! Let's just start with the
definition of the meaty one, `formattedNumberField`. Arguments:

1. The field's label (previously mentioned)
2. A formatter function that takes a model and results in a String that should
	display the human-friendly version of the underlying numerical value
3. The getter (previously mentioned)
4. A `Msg` constructor (previously mentioned)
5. The model (previously mentioned)

`Select.elementId label` is just an Elm port that will run `select()` on the
text input element. This will cause the entire input to be selected `onFocus`,
which makes quick data entry a bit easier.

It also introduces a few more onion bits that our "compiler-driven development"
methodology will require us to write:

+ `numberField` which should result in some HTML
+ `unFormat` which should, given a string, result in the raw numerical value

Alright. We're getting closer. Stay with me now.

More code:

```elm
numberField : FieldConfig String model msg -> model -> Html msg
numberField config model =
	Html.div [ Html.Attributes.class "field" ]
		[ Html.label []
			[ Html.text config.label
			]
		, Html.input
			[ Html.Attributes.value (config.value model)
			, Html.Attributes.id
				(config.label
					|> String.replace " " "_"
				)
			, Html.Events.onInput config.onInput
			, Html.Events.onFocus (config.onFocus model)
			, Html.Events.onBlur (config.onBlur model)
			]
			[]
		]

unFormat : String -> String
unFormat s =
	s
		|> String.replace "," ""
		|> String.replace "$" ""
		|> String.replace "%" ""
```

Lo and behold! Some actual `Html` module calls! This bit of code is pretty
self-explanatory and so I won't get too into it. With that, we've done it! Our
basic form fields setup is complete!

I hope you were able to follow all of this. If you have ideas on how to improve
it, please get in touch!

Altogether now...

## Full Source

-- TODO

[1]: https://github.com/hecrj/composable-form
[2]: https://github.com/hecrj/composable-form/blob/dd846d84de9df181a9c6e8803ba408e628ff9a93/src/Form/Base.elm#L26
