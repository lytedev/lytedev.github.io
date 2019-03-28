---
image: "/img/teal-bubbles.jpg"
date: "2019-03-28T10:30:00-05:00"
imageOverlayColor: "#000"
imageOverlayOpacity: 0.5
heroBackgroundColor: "#333"
description: "Clean and functional Admin CRUD forms using the metadata already
in your schemas!"
title: Using Ecto Reflection for Simple Admin CRUD Forms in Elixir's Phoenix
draft: false
---

If you're working on a Phoenix project, you probably realized the client might
want to view (or even -- *gasp* -- edit!) their data in a pretty raw form.
Frameworks like [Django][django] provide this out of the box.
[Phoenix][phoenix], however, leaves this up to you!

<!--more-->

Sure, there are [`ex_admin`][ex_admin] and [Torch][torch], but `ex_admin` is
pretty much abandoned and Torch is more of a form generator. Personally, I'm not
really a fan of code generators. In my opinion, if something can generate code,
why doesn't it just offer whatever functionality is being provided by the
generated code?

I'll share what I did and hopefully this helps you!

# TL;DR

Leverage your Ecto schemas' [`__schema__/1`][__schema__] and
[`__schema__/2`][__schema__] functions to retrieve the fields and associations
metadata created when using the [`schema/2`][schema/2] macro. From there, you
can decide how to render an appropriate HTML field in a form. From there, you
can either use [`Ecto.Changeset.change/2`][Ecto.Changeset.change/2] to handle
the results of an admin user submitting those forms or implement some sort of
protocol that lets you specify an admin-specific changeset.

## Getting That Sweet, Sweet Metadata

My first issue was figuring out how to get the metadata that I knew Ecto already
had about my schemas. Y'know, which fields are which types, so that I could use
that metadata to render the appropriate form elements: a text box for
a `:string`, a checkbox for a `:boolean`, a [`multiple`
select][select_attributes] for a [`many_to_many/3`][many_to_many/3] association,
etc.

After asking in the ever-helpful [Elixir Slack][elixir-slack], somebody
mentioned that Ecto Schemas [supported reflection][__schema__] using
a `__schema__` method that could access what I was looking for.

```elixir
iex(1)> MyApp.Accounts.User.__schema__ :fields
[:id, :email, :full_name, :password_hash, :verified, :inserted_at, :updated_at]
iex(2)> MyApp.Accounts.User.__schema__ :associations
[:roles]
iex(3)> MyApp.Accounts.User.__schema__ :type, :id
:id
iex(4)> MyApp.Accounts.User.__schema__ :type, :email
:string
iex(5)> MyApp.Accounts.User.__schema__ :association, :roles
%Ecto.Association.ManyToMany{
  cardinality: :many,
  defaults: [],
  field: :roles,
  join_keys: [user_id: :id, role_id: :id],
  join_through: MyApp.Accounts.UserRole,
  on_cast: nil,
  on_delete: :nothing,
  on_replace: :raise,
  owner: MyApp.Accounts.User,
  owner_key: :id,
  queryable: MyApp.Accounts.Role,
  related: MyApp.Accounts.Role,
  relationship: :child,
  unique: false,
  where: []
}
iex(6)> "siiiiiiiiiick"
...
```

Awesome! Using this, I can *definitely* construct a basic form!

So, we'll want an admin controller that knows how to add new schema entries
generically as well as edit and update existing ones:

```elixir
# admin_controller.ex

@models %{
	"user" => MyApp.Accounts.User,
	"role" => MyApp.Accounts.Role
	# ... and any other possible schema you have!
}

def edit(conn, %{"schema" => schema, "pk" => pk}) do
	schema_module = @models[schema]

	model = schema_module.__schema__(:associations)
		|> Enum.reduce(MyApp.Repo.get(m, pk), fn a, m ->
			MyApp.Repo.preload(m, a)
		end)

	# TODO: load changeset from session?
	opts = [
		changeset: Ecto.Changeset.change(model, %{}),
		schema_module: schema_module,
		schema: schema,
		pk: pk
	]
	render(conn, "edit.html", opts)
end

# create/2 works similarly and may be considered an exercise for the reader =)
def update(conn, %{"schema" => schema, "pk" => pk, "data" => data}) do
	schema_module = @models[schema]

	# TODO: be wary! this lets an admin change EVERYTHING!
	# if you want to avoid this like I did, setup an AdminEditable protocol that
	# requires your schema to implement an admin-specific changeset and use that
	# instead
	changeset = Ecto.Changeset.change(MyApp.Repo.get!(module, pk), data)

	case MyApp.Repo.update(changeset) do
		{:ok, updated_model} ->
			conn
			|> put_flash(:info, "#{String.capitalize(schema)} ID #{pk} updated!")
			|> redirect(to: Routes.admin_path(conn, :edit, schema, pk))

		{:error, changeset} ->
			conn
			|> put_flash(:failed, "#{String.capitalize(schema)} ID #{pk} failed to update!")
			|> put_session(:changeset, changeset)
			|> redirect(to: Routes.admin_path(conn, :edit, schema, pk))
	end
end
```

Yep. That's a lot of code. The first chunk to define the `@models` module
attribute is very simple: map a string to a schema module. Easy. If we want, we
could have this map to a tuple like `"user" => {Module, "user", "users"}` so we
could control how they're displayed as well, passing this information to the
view.

The `edit/2` method takes a schema type (to map to a schema module via
`@models`) and a primary key so we can retrieve the actual entry for that
schema. Generally, this will be a UUID or an integer, but it could be something
more complex, in which case your `router.ex` will probably need unusual help to
accommodate this route.

Anyway, `edit/2` just grabs the schema module and loads the given entry, using
the reflection we saw earlier to go ahead and preload all the associations.
Neat! We also create a blank changeset and pass these important things on to our
view. `new/2` is left as an exercise all for you! But mostly because I haven't
written it yet myself! I'm also not retrieving the changeset from the session
here. I also leave that up to you.

`update/2` works similarly, grabbing the schema module, creating a changeset
from the given data (note the big warning!), and then attempting to update the
repo. Here, we have some reasonable error handling and proper Phoenix CRUD'ing
-- or at least... U'ing, but that doesn't sound as fun.

This gets us really close to being able to update arbitrary schema entries! We
just need to setup the view to know how to handle the view logic (duh).

First, though, let's go to our template and figure out how we want it to work,
then we know what helper functions we'll need in our view.

Oh, by the way, I'm using [Slime][slime] instead of [EEx][eex] for my
templates. If you haven't heard of it, you should check it out. It makes for
very clean template code.

```elixir
# edit.html.slime

h1
	= "Edit #{String.capitalize(to_string(@schema))}"
	= " ID #{@id}"

- action_path = Routes.admin_path(@conn, :update, @schema, @id)
= form_for @changeset, action_path, [as: :data], fn f ->
	h2 Fields

  = for field <- @schema_module.__schema__(:fields) do
		.field
			label
				.label-text #{String.capitalize(to_string(field))}
				= field(f, @schema_module, field)

	h2 Associations

	= for association <- @schema_module.__schema__(:associations) do
		.field
			label
				.label-text #{String.capitalize(to_string(association))}
				= association(f, @schema_module, association)
```

Wow, this is cool! Obviously, most of the magic is going to be in the view
functions we now have to implement, but this *one* view will theoretically
handle any basic schema! This is great!

If you're locking down which fields an admin can modify, you can do something
like this:

```elixir
# edit.html.slime

# for field in fields...

.field
	label
		.label-text #{String.capitalize(to_string(field))}
		= if Enum.member?(@editable_fields, field) do
			= field(f, @schema_module, field)
		- else
			input readonly="true" value=Map.get(@changeset.data, field)
```

Let's get to the nitty gritty and implement `field/3` and `association/3`:

```elixir
def field(form, schema_module, field, opts \\ []) do
	case schema_module.__schema__(:schema, field) do
		:boolean -> Phoenix.HTML.Form.checkbox(form, field, opts)
		:integer -> Phoenix.HTML.Form.number_input(form, field, opts)
		# ... I haven't implemented any other types, yet, but datetimes and other
		# such fields shouldn't be too difficult!
		# see: https://hexdocs.pm/phoenix_html/Phoenix.HTML.Form.html#functions
		_ -> Phoenix.HTML.Form.text_input(form, field, opts)
	end
end

def association(form, schema_module, association, opts \\ []) do
	association = schema_module.__schema__(:association, association)

	# make sure your schemas implement the `String.Chars` protocol so they can
	# look nice in a select!
	# obviously, if you have massive tables, `Repo.all/1` is a bad idea!
	options = MyApp.Repo.all(association.queryable)
		|> Enum.map(&{&1.id, to_string(&1)})

	case association.cardinality do
		:many ->
			opts = Keyword.put_new(opts, :multiple, true)
			Phoenix.HTML.Form.select(form, association, options, opts)
		_ ->
			Phoenix.HTML.Form.select(form, association, options, opts)
	end
end
```

Holy cow! Not bad at all! Actually, it would be really easy to extend this and
even handle the wacky edge cases that may come down the line! As previously
mentioned implementing some kind of `AdminEditable` protocol would be ideal,
then you could attach whatever metadata you wanted in order for your admin CRUD
system to work exactly how you want.

I'm doing that since I don't actually want an admin to be able to change certain
things that the system is solely responsible for. This includes primary keys,
slugs, user-provided information, etc. Therefore this looks a bit different in
practice on my end.

```elixir
# accounts/user.ex

defimpl MyApp.AdminEditable, for: MyApp.Accounts.User do
  @readable [:id, :email, :full_name, :inserted_at, :updated_at]
  @editable [:verified]

  def admin_readable_fields(_s), do: @readable ++ @editable
  def admin_editable_fields(_s), do: @editable

	# this controls what shows up on the index for a given schema
  def admin_index_fields(s), do: admin_readable_fields(s)
end
```

You could then use these methods instead of schema reflection. You could also
handle associations separately as well.

```elixir
# accounts/user.ex

# defimpl MyApp.AdminEditable ...

@readable_associations []
@editable_associations [:roles]

def admin_readable_associations(_s), do:
	@readable_associations ++ @editable_associations
def admin_editable_fields(_s), do: @editable_associations
```

You could use this *and* define the implementation for `Any` *and* use the
aforementioned schema reflection and get the best of both worlds!

Anyways, I have a billion ideas on how to extend this basic concept. Hopefully
you can implement your own admin interface without writing a form for every
single schema you have, too! Ahh, simplicity.

Here's all the code jumbled together (and perhaps slightly different):

## All Together Now!

```elixir
# router.ex

get("/edit/:schema/:pk", AdminController, :edit)
post("/new/:schema/:pk", AdminController, :create)
put("/update/:schema/:pk", AdminController, :update)

# admin_controller.ex

@models %{
	"user" => MyApp.Accounts.User,
	"role" => MyApp.Accounts.Role
	# ... and any other possible schema you have!
}

def edit(conn, %{"schema" => schema, "pk" => pk}) do
	schema_module = @models[schema]

	model = schema_module.__schema__(:associations)
		|> Enum.reduce(MyApp.Repo.get(m, pk), fn a, m ->
			MyApp.Repo.preload(m, a)
		end)

	# TODO: load changeset from session?
	opts = [
		changeset: Ecto.Changeset.change(model, %{}),
		schema_module: schema_module
	]
	render(conn, "edit.html", opts)
end

# create/2 works similarly and may be considered an exercise for the reader =)
def update(conn, %{"schema" => schema, "pk" => pk, "data" => data}) do
	schema_module = @models[schema]

	# TODO: be wary! this lets an admin change EVERYTHING!
	# if you want to avoid this like I did, setup an AdminEditable protocol that
	# requires your schema to implement an admin-specific changeset and use that
	# instead
	changeset = Ecto.Changeset.change(MyApp.Repo.get!(module, pk), data)

	case MyApp.Repo.update(changeset) do
		{:ok, updated_model} ->
			conn
			|> put_flash(:info, "#{String.capitalize(schema)} ID #{pk} updated!")
			|> redirect(to: Routes.admin_path(conn, :edit, schema, pk))

		{:error, changeset} ->
			conn
			|> put_flash(:failed, "#{String.capitalize(schema)} ID #{pk} failed to update!")
			|> put_session(:changeset, changeset)
			|> redirect(to: Routes.admin_path(conn, :edit, schema, pk))
	end
end

# admin_view.ex

def field(form, changeset, schema_module, field, opts \\ []) do
	# this is pretty much the result of the magic - render a partial, look at
	# additional metadata, etc!
	case schema_module.__schema__(:schema, field) do
		:boolean -> Phoenix.HTML.Form.checkbox(form, field, opts)
		_ -> Phoenix.HTML.Form.text_input(form, field, opts)
	end
end

def association(form, changeset, schema_module, association, opts \\ []) do
	# similar magic for associations! huzzah!
	association = schema_module.__schema__(:association, association)

	# make sure your schemas implement the `String.Chars` protocol!
	options = MyApp.Repo.all(association.queryable)
		|> Enum.map(&{&1.id, to_string(&1)})

	case association.cardinality do
		:many ->
			Phoenix.HTML.Form.select(form, association, options, Keyword.put_new(opts, :multiple, true))
		_ ->
			Phoenix.HTML.Form.select(form, association, options, opts)
	end
end

# new.html.slime is similar and also an exercise for the reader =)
# edit.html.slime

= form_for @changeset, Routes.admin_path(@conn, :update, @schema, @id), [as: :data], fn f ->
	h2 Fields

  = for field <- @schema_module.__schema__(:fields) do
		.field
			label
				.label-text #{String.capitalize(to_string(field))}
				= field(f, @changeset, @schema_module, field)

	h2 Associations

	= for association <- @schema_module.__schema__(:associations) do
		.field
			label
				.label-text #{String.capitalize(to_string(association))}
				= association(f, @changeset, @schema_module, association)
```

[django]: https://www.djangoproject.com/
[phoenix]: https://phoenixframework.org/
[ex_admin]: https://github.com/smpallen99/ex_admin
[torch]:https://github.com/danielberkompas/torch
[__schema__]: https://hexdocs.pm/ecto/3.0.7/Ecto.Schema.html#module-reflection
[schema/2]: https://hexdocs.pm/ecto/3.0.7/Ecto.Schema.html#schema/2
[Ecto.Changeset.change/2]: https://hexdocs.pm/ecto/3.0.7/Ecto.Changeset.html#change/2
[elixir-slack]: https://elixir-slackin.herokuapp.com/
[select_attributes]:https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select#Attributes
[many_to_many/3]: https://hexdocs.pm/ecto/3.0.7/Ecto.Schema.html#many_to_many/3
[slime]: https://github.com/slime-lang/slime
[eex]: https://hexdocs.pm/eex/EEx.html
