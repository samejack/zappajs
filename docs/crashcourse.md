---
layout: default
title: Crash Course
---

# {{page.title}}

Yes indeed, here we are. Let's begin with the classic:

## Hi, World

Get a `cuppa.coffee`:

    require('zappajs') ->
      @get '/': 'hi'

And give your foot a push:

    $ npm install zappajs
    $ coffee cuppa.coffee
       info  - socket.io started
    Express server listening on 0.0.0.0:3000 in development mode
    Zappa 1.0.5 orchestrating the show

(hat tip to [sinatra](http://sinatrarb.com))

## OK, what did just happen?

`require 'zappajs'` returns a function you can use to run your apps. We're calling it right away and passing an anonymous function as the parameter.

The zappa function does the initial express and socket.io setup, then calls your function with the relevant stuff exposed at `this` (and its CoffeeScript alias `@`).

You have direct access to the low-level APIs via `@app` and `@io`:

    require('zappajs') ->
      @app.get '/', (req, res) ->
        res.send 'boring!'
      @io.sockets.on 'connection', (socket) ->
        socket.emit 'boring'

On top of that, you also have some handy shortcuts such as the `@get` you already know, `@on` (to define *socket.io* handlers), `@use`, `@set`, etc. Those are not only shorter but also accept smarter parameters:

    require('zappajs') ->
      @get '/foo': 'bar', '/ping': 'pong', '/zig': 'zag'
      @use (require 'body-parser').urlencoded(), 'method-override', 'static'
      @set 'view engine': 'jade', views: "#{__dirname}/custom/dir"

After running your function, zappa automatically starts the whole thing and spits out a message with some useful info.

## What about \[ENTER OPTION HERE\]?

Of course you can run your app in a different port and/or host:

    require('zappajs') 'domain.com', 80, ->
      @get '/': 'hi'

Get a reference without running it automatically:

    chat = require('zappajs').app ->
      @get '/': 'hi'

    chat.server.listen 3000

And so on. To see all the options, check the [API reference](http://zappajs.github.com/zappajs/docs/reference).

## Nice, but one-line string responses are mostly useless. Can you show me something closer to a real web app?

    @get '*': '''
      <!DOCTYPE html>
      <html>
        <head><title>Oops</title></head>
        <body><h1>Sorry, check back in a few minutes!</h1></body>
      </html>
    '''

## Seriously.

Right. This is what a basic route with a handler function looks like:

    @get '/:name': ->
      "Hi, #{@params.name}"

As you can see, the value of `this` is modified in the handler function too, giving you quick access to everything you need to handle the request. The low level API lives at `@request`, `@response` and `@next`, but you also have handy shortcuts such as `@render`, `@redirect`, `@query`, `@params`, etc.

If you return a string, it will automatically be sent as the response. But most of the time you'll be doing something asynchronous, and in this case you have to call `@send`:

    @get '/ponchos/:id': ->
      Poncho.findById @params.id, (error, poncho) =>
        # Is that a real poncho, or is that a sears poncho?
        @send poncho.type

Note that we're using a fat arrow (`=>`) here, to preserve the value of `this`.

## Radical views

Generally `@render` works just like `@response.render`:

    @get '/': ->
      @render 'index', foo: 'bar'

One difference is that it also works with the "key: value syntax":

    @get '/': ->
      @render index: {foo: 'bar'}

Another is that you can define inline views:

    @get '/': ->
      @render index:
        foo: 'bar'
        title: 'Inline template'

    {doctype,html,head,body,h1,p} = @teacup
    @view index: ->
      doctype 5
      html =>
        head => title @title
        body =>
          h1 @title
          p @foo

Note that zappa comes with a default templating engine, [teacup](https://goodeggs.github.io/teacup), and you don't have to setup anything to use it. You can also easily use other engines by specifying the file extension or the `'view engine'` setting; it's just express. Well, express + inline views support:

    @engine 'eco', require('consolidate').eco
    @set 'view engine': 'eco'

    @get '/': -> @render index: {foo: 'bar', title: 'Eco template'}
    @get '/jade': -> @render 'index.jade': {foo: 'bar', title: 'Jade template'}

    @view index: '''
      <!DOCTYPE html>
      <html>
        <head><title><%= @title %></title></head>
        <body>
          <h1><%= @title %></h1>
          <p><%= @foo %></p>
        </body>
    '''

    @view 'index.jade': '''
      doctype html
      html
        head
          title= title
        body
          h1= title
          p= foo
    '''

## Knock your sockets off

Using socket.io in zappa is just a matter of defining the event handlers with `@on`:

    require('zappajs') ->
      @get '/': ->
        @render 'index'

      @on connection: ->
        @emit welcome: {@id}

      @on shout: ->
        @broadcast shouted: {@id, text: @data.text}

Socket.io is automatically required and attached to the express server, intercepting WebSockets/comet traffic on the same port.

Just like in request handlers, the value of `this` is modified to include all the relevant stuff you need, including the low-level API (here at `@socket` and `@io`) and smart shortcuts (`@id`, `@emit`, `@broadcast`, etc). Input variables are available at `@data`.

On the client-side, you can use the vanilla socket.io API if you like, but that wouldn't make much sense, would it? Which leads us to...

## The client side of the source

With `@coffee`, you can define client-side code inline, and serve it in JS form with the correct content-type set. No compilation involved, since we already have its string representation from the runtime:

    @get '/': ->
      @render 'index'

    @coffee '/index.js': ->
      alert 'hullo'

    {doctype,html,head,script,body,h1} = @teacup
    @view index: ->
      doctype 5
      html ->
        head -> title 'bla'
        script src: '/index.js'
      body ->
        h1 'Inline client example'

On a step further, you have `@client`, which gives you access to a matching client-side zappa API:

    @get '/': ->
      @render 'index'

    @on connection: ->
      @emit time: {time: new Date()}

    @client '/index.js': ->
      @get '#/foo': ->
        $('body').append 'client-side route with sammy.js'

      @on time: ->
        $('body').append "Server time: #{@data.time}"

      @connect()

    {doctype,html,head,title,script,body} = @teacup
    @view index: ->
      doctype 5
      html ->
        head ->
          title 'Client-side zappa'
          script src: '/zappa/full.js'
          script src: '/index.js'
        body ''

Finally, there's `@shared`. This block of code is not only served to the client, but also executed on the server.

    @shared '/shared.js': ->
      root = window ? global
      root.sum = (x, y) ->
        String(Number(x) + Number(y))

    # This uses global.sum (on the server).
    @get '/sum/:x/:y': ->
      @send sum(@params.x, @params.y)

    # This uses window.sum (on the client).
    @coffee '/index.js': ->
      $ =>
        $('button').click =>
          $('#result').html(sum $('#x').html(), $('#y').html())

## Santa's little helpers

Zappa helpers are functions with automatic access to the same context (`this`/`@`) as whatever called them (request or event handlers):

    @helper map: (name) ->
      map = maps[name]
      format = if @request? then @query.format else @data.format

      if format is 'xml'
        map = map.toXML()
      else
        map = map.toJSON()

      if @request?
        @send map
      else
        @emit map: {map}

    @get '/maps/dungeon': ->
      @map 'dungeon'

    @on 'enter dungeon': ->
      @map 'dungeon'

## Including modules

Besides good ol' `require`, zappa also provides `@include`, which not only requires a file, but also calls an exported function named `include`, setting the value of `this` to the same context:

    @include 'http'
    @include 'websockets'

Then in `http.coffee`:

    # Same as module.exports.include
    @include = ->
      @get '/foo': -> @render 'foo'
      @get '/bar': -> @render 'bar'
      # ...

And `websockets.coffee`:

    @include = ->
      @on foo: -> @emit 'foo'
      @on bar: -> @emit 'bar'
      # ...

## Connect(ing) middleware

You can specify your middleware through the standard `@app.use`, or zappa's shortcut `@use`. The latter can be used in a number of additional ways:

It accepts many params in a row. Ex.:

    @use (require 'body-parser').urlencoded, (require 'cookie-parser')()

It accepts strings as parameters. This is syntactic sugar to the equivalent express middleware with no arguments. Ex.:

    @use 'cookie-parser'

You can also specify parameters by using objects. Ex.:

    @use static: __dirname + '/public', session: {secret: 'fnord'}, 'cookie-parser'

Finally, when using strings and objects, zappa will intercept some specific middleware and add behaviour, usually default parameters. Ex.:

    @use 'static'

    # Syntactic sugar for:
    @app.use @express.static(__dirname + '/public')

Note: `static` is a ZappaJS wrapper for `server-static`, `session` a wrapper for `express-session`. You should use those instead of the original modules for full Zappa effect.

## Aaaaaand that's it for tonight.

Thank you for coming to the show, hope you enjoyed it. [CoffeeScript](https://coffeescript.org) on guitar, [Express](http://expressjs.com) on the keyboards, [Socket.IO](http://socket.io) on drums. [Node.js](http://nodejs.org) on background vocals, [npm](http://npmjs.org) on bass. G'night everyone.

To learn more, check out [the links](http://zappajs.github.com/zappajs/) at the home page.
