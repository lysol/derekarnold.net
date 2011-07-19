express = require 'express'
blog = require './blog'
eco = require 'eco'
app = module.exports = express.createServer()

# Setup Template Engine
app.set 'views', __dirname + '/views'
app.set 'view engine', 'eco'
app.set 'view options', layout: 'layout'
#app.register '.eco', eco
blog.set 'article path', './articles'
app.use express.bodyParser()
app.use express.methodOverride()
app.use express.cookieParser()
app.use app.router

# Setup Static Files
app.use express.static __dirname + '/public'

class Nav
  constructor: (@token, @name) ->

navs = []
navs.push new Nav '', 'Home'
navs.push new Nav 'resume', 'Résumé'
navs.push new Nav 'blog', 'Blog'

# App Routes

app.get '/', (request, response) ->
  response.render 'index',
    "navs": navs
    current_nav: navs[0]

app.get '/resume', (request, response) ->
  response.render 'resume',
    "navs": navs
    current_nav: navs[1]

app.get /^\/blog\/?.*/, (request, response) ->
  blog.render(request, response)

# Listen
app.listen 3000
console.log "Listening on port 3000."