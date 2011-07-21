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
    title_bar: 'Derek Arnold'

app.get '/resume', (request, response) ->
  response.render 'resume',
    "navs": navs
    current_nav: navs[1]
    title_bar: 'Derek Arnold - Résumé'

app.get '/blog/post/:token', (request, response) ->
  blog.get_post req.params.token, (post) ->
    blog.attach_body post, (newpost) ->
      response.render 'blog_post',
        "post": newpost
        current_nav: navs[2]
        title_bar: "Derek Arnold - Blog - #{post.title}"

app.get '/blog/page/:page', (request, response) ->
  resCb = (posts) ->
    blog.attach_bodies posts, (newposts) ->
      response.render 'blog',
        "posts": newposts
        current_nav: navs[2]
        title_bar: "Derek Arnold - Blog - Page #{req.params.page}"
  blog.get_posts resCb, req.params.page

app.get '/blog', (request, response) ->
  blog.get_posts (posts) ->
    blog.attach_bodies posts, (newposts) ->
      response.render 'blog',
        "navs": navs
        "posts": newposts
        current_nav: navs[2]
        title_bar: 'Derek Arnold - Blog'

# Listen
app.listen 3000
console.log "Listening on port 3000."