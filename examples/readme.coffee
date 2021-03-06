# This is the example from README.md
require('./zappajs') ->

  # Server-side

  @get '/': ->
    @render 'index',
      title: 'Zappa!'
      scripts: '/zappa/simple.js /index.js /client.js'
      stylesheet: '/index.css'

  {doctype,html,head,title,script,link,body,h1,div} = @teacup
  @view index: ->
    doctype 5
    html =>
      head =>
        title @title if @title
        for s in @scripts.split ' '
          script src: s
        link rel:'stylesheet', href:@stylesheet
      body ->
        h1 'Welcome to Zappa!'
        div id:'content'

  @css '/index.css':
    body:
      font: '12px Helvetica'
    h1:
      color: 'pink'

  @get '/:name/data.json': ->
    record =
      id: 123
      name: @params.name
      email: "#{@params.name}@example.com"
    @send record

  @on 'ready': ->
    console.log "Client #{@id} is ready and says #{@data}."

  # Client-side

  @coffee '/index.js': ->
    alert 'hi'

  @client '/client.js': ->
    @connect()

    $ =>
      @emit 'ready', 'hello'

    @get '#/': ->
      @app.swap 'Ready to roll!'
