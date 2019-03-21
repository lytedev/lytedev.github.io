---
image: "/img/dried-lava.jpg"
date: "2019-03-20T20:24:54-05:00"
imageOverlayColor: "#000"
imageOverlayOpacity: 0.5
heroBackgroundColor: "#333"
description: "If you're using Elm, you're probably dealing with forms and
fields. Here's how I did!"
title: "Elm: Forms, Fields, and Abstractions"
draft: false
---

If you're using Elm, you're probably dealing with forms and fields. You're also
probably wanting to do functional programming "right" and compose smaller
functions together. Hopefully this helps!

<!--more-->

# TL;DR

Check it out in context on
<a href="https://ellie-app.com/53ypTnnFykXa1" target="_blank">Ellie</a>,
the Elm playground!

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

To be fair, technically this is appropriately "composable", as you are given the
minimum functioning piece so that you can bolt whatever you need onto it, but as
soon as a library or module isn't *easily* doing what I need it to do, instead
of copying code from it, I'm just going to roll my own, which is generally
a really good way to learn something anyways. So, while frustrated, I was also
eager to tackle the problem.

## Code Already!

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
-- ... imports and module definitions ...
main =
	Browser.element
		{ init = init
		, update = update
		, subscriptions = \m -> Sub.none
		, view = view
		}

type alias Model =
	{ amount : String
	, ratePercent : String
	}

init : () -> ( Model, Cmd msg )
init _ =
	( { amount = "$1000.87" |> currency
		, ratePercent = "3.427857%" |> percent
		}
	, Cmd.none
	)

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
	Html.div []
		[ form model
			[ currencyField "Amount" .amount UpdateAmount
			, percentField "Rate" .ratePercent UpdateRatePercent
			]
```

I want this code to handle rendering my fields, formatting and un-formatting the
text input's value (more on this later), and firing update `Msg`s accordingly.
So we just need to implement the `form` function and the `currencyField` and
`percentField` functions.

Note that I'm storing my values as a string in this case, even though my intent
is for them to be numbers. I'm sure there is a cool Elm way to handle this using
the type system, but I haven't got that far. For the moment I'm just extracting
the value from them whenever the calculations need to be done (not shown here).
If and when that changes, perhaps I can make that another blog post explaining
that process as well!

Let's start with form, since it should be the simplest.

```elm
form : model -> List (model -> Html msg) -> Html msg
form model fields =
	Html.form []
		(List.map (\f -> f model) fields)
```

All the `form` function does is create an `Html.form` whose children are just
the result of mapping over the list of fields, calling "view-like" functions,
passing the model. Easy. Now your form function may need stuff like submit
buttons or other actions, but mine does not. Again, do what is necessary for
*your* application!

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
	formattedNumberField label (\m -> m |> getter |> currency) getter updateMsg model

percentField : String -> (model -> String) -> (String -> Cmd msg -> msg) -> model -> Html msg
percentField label getter updateMsg model =
	formattedNumberField label (\m -> m |> getter |> percent) getter updateMsg model
```

Whew! I know these type signatures can look intimidating if you're new to Elm,
but here's the breakdown of the arguments:

1. The field's label (as we've seen in the call)
2. A getter, which, given a model, can provide the text that the input should
	 display (as we've seen in the call - [here's an explanation][4])
3. A `Msg` constructor that takes a `String` (which is passed from `onInput`)
	 and a `Cmd msg`, since in some cases we might wanna do that, but I won't get
	 into that here (as we've seen in the call)
4. The model

Okay! That all makes sense. Now what's up with `formattedNumberField`? That's
the next layer of the abstraction onion I'm building up. It's for any number
field that needs to unformat with `onFocus` and reformat with `onBlur`. Also,
we're going to ignore `currency` and `percent` (thought the full code will have
it) as that brings in a whole lot of code that's mostly unrelated to the core
concept I'm trying to convey here. Basically, they take a string like "4.8" and
convert that to "$4.80" or "4.80%".

Now we might also have a number field that doesn't necessarily care about
handling `onFocus` or `onBlur`, so we'll have another abstraction layer there
called `numberField`. Let's see the code:

```elm
type alias FieldConfig t model msg =
	{ label : String
	, value : model -> t
	, onInput : t -> msg
	, onFocus : model -> msg
	, onBlur : model -> msg
	, class : model -> String
	}

numberField : FieldConfig String model msg -> model -> Html msg
numberField config model =
	Html.div [ Html.Attributes.class "field" ]
		[ Html.label []
			[ Html.text config.label
			]
		, Html.input
			[ Html.Attributes.value (config.value model)
			, Html.Attributes.class (config.class model)
			, Html.Attributes.pattern "[0-9\\.]"
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
		
formattedNumberField : String -> (model -> String) -> (model -> String) -> (String -> Cmd msg -> msg) -> model -> Html msg
formattedNumberField label formatter getter updateMsg model =
	numberField
		-- FieldConfig
		{ label = label
		, value = getter
		, onInput = \s -> updateMsg s Cmd.none
		, onFocus = \m -> updateMsg (m |> getter |> unFormat) (selectElementId label)
		, onBlur = \m -> updateMsg (formatter m) Cmd.none
		, class = \m -> m |> getter |> unFormat |> String.toFloat |> numberFieldClass
		}
		model
```

Alrighty! Our biggest chunk. The first block is just a type that tells the
compiler what kind of things we're going to need to build a field. Most of them
are functions that take a model and result in either the type of the field,
a msg to update our model with, or some attribute used within the field for
UX-related things, such as validation.

The second chunk, `numberField` is perhaps the most familiar to newbies and
straightforward. It takes a `FieldConfig`, which we just talked about, and
a model and turns that into HTML that can trigger the messages as specified in
the config. At a glance, it looks pretty magical, but hopefully the next chunk
makes it clear.

`formattedNumberField` specifies the `FieldConfig` which houses all the magic.
It's pretty much a bunch of lambda functions that know how to take a model and
create a `Msg`, which runs through our `update` function, which is that really
important piece of [The Elm Architecture][5].

There are a lot of functions in there like `unFormat`, `numberFieldClass`, and
`selectElementId` that you can check out in the full example, but (again) aren't
really relevant to the core of what I'm talking about.

Hopefully this all makes sense. If it doesn't, check out the full example after
the jump for a working example that you can play with. If this is "Elm 101" to
you, awesome! It took me some serious mind-bending and frustration with Elm's
incredible type checking system not implicitly understanding what I'm trying to
do (computers, amirite?) before I made it to this point.

Now, I'm confident Elm is a tool that can do everything I need it to do. I look
forward to using it more in the future!

## Full Source

Check it out in context on
<a href="https://ellie-app.com/53ypTnnFykXa1" target="_blank">Ellie</a>,
the Elm playground!

[1]: https://github.com/hecrj/composable-form
[2]: https://github.com/hecrj/composable-form/blob/dd846d84de9df181a9c6e8803ba408e628ff9a93/src/Form/Base.elm#L26
[3]: https://github.com/hecrj/composable-form/blob/dd846d84de9df181a9c6e8803ba408e628ff9a93/src/Form.elm
[4]: https://elm-lang.org/docs/records#access
