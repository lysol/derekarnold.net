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
navs.push new Nav '', 'Blog'
navs.push new Nav 'resume', 'Résumé'
navs.push new Nav 'about', 'About'

# App Routes

app.get '/about', (request, response) ->
  response.render 'index',
    "navs": navs
    current_nav: navs[2]
    title_bar: 'Derek Arnold'

app.get '/resume', (request, response) ->
  response.render 'resume',
    "navs": navs
    current_nav: navs[1]
    title_bar: 'Derek Arnold - Résumé'

app.get '/post/:token', (request, response) ->
  blog.get_post request.params.token, (post) ->
    blog.attach_body post, (newpost) ->
      response.render 'blog_post',
        "navs": navs
        "post": newpost
        current_nav: navs[0]
        title_bar: "Derek Arnold - Blog - #{post.title}"

app.get '/page/:page', (request, response) ->
  pageNum = parseInt request.params.page
  resCb = (posts) ->
    blog.attach_bodies posts, (newposts) ->
      resCb2 = (nextprev) ->
        response.render 'blog',
          "navs": navs
          "posts": newposts
          show_next: nextprev[0]
          show_prev: nextprev[1]
          current_nav: navs[0]
          page: parseInt request.params.page
          basePath: "/"
          title_bar: "Derek Arnold - Blog - Page #{pageNum}"
      blog.paginates resCb2, pageNum
  blog.get_posts resCb, pageNum

app.get '/', (request, response) ->
  blog.get_posts (posts) ->
    blog.attach_bodies posts, (newposts) ->
      blog.paginates (nextprev) ->
        response.render 'blog',
          show_next: nextprev[0]
          show_prev: nextprev[1]
          "navs": navs
          "posts": newposts
          page: 1
          current_nav: navs[0]
          basePath: "/"
          title_bar: 'Derek Arnold - Blog'


app.get '/tags/:tag/:page', (request, response) ->
  tag = request.params.tag
  page = request.params.page
  pCb = (posts) ->
    blog.attach_bodies posts, (newposts) ->
      pagCb = (nextprev) ->
        response.render 'blog',
          show_next: nextprev[0]
          show_prev: nextprev[1]
          "navs": navs
          "posts": newposts
          "page": page
          current_nav: navs[0]
          "tag": tag
          basePath: "/tags/#{tag}/"
          title_bar: "Derek Arnold - Blog - Tagged: #{tag} - Page #{page}"
      blog.paginates pagCb, tag
  blog.get_posts pCb, page, tag


app.get '/tags/:tag', (request, response) ->
  tag = request.params.tag
  pCb = (posts) ->
    blog.attach_bodies posts, (newposts) ->
      pagCb = (nextprev) ->
        response.render 'blog',
          show_next: nextprev[0]
          show_prev: nextprev[1]
          "navs": navs
          "posts": newposts
          page: 1
          "tag": tag
          current_nav: navs[0]
          title_bar: "Derek Arnold - Blog - Tagged: #{tag}"
          basePath: "/tags/#{tag}/"
      blog.paginates pagCb, tag
  blog.get_posts pCb, 1, tag


# Listen
app.listen 3000
console.log "Listening on port 3000."