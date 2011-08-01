express = require 'express'
blog = require './blog'
eco = require 'eco'
app = module.exports = express.createServer()
fs = require 'fs'
datejs = require 'datejs'

# Setup Template Engine
app.set 'views', __dirname + '/views'
app.set 'view engine', 'eco'
app.set 'view options', layout: 'layout'
#app.register '.eco', eco
blog.set 'article path', __dirname + '/articles'
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

config = {}

# App Routes

app.get '/about', (request, response) ->
  response.render 'about',
    "navs": navs
    current_nav: navs[2]
    title_bar: config.siteName
    siteDescription: config.siteDescription

app.get '/resume', (request, response) ->
  response.render 'resume',
    "navs": navs
    current_nav: navs[1]
    title_bar: "#{config.siteName} - Résumé"
    siteDescription: config.siteDescription

app.get '/post/:token', (request, response) ->
  blog.get_post request.params.token, (post) ->
    blog.attach_body post, (newpost) ->
      response.render 'blog_post',
        "navs": navs
        "post": newpost
        current_nav: navs[0]
        title_bar: "#{config.siteName} - Blog - #{post.title}"
        useDisqus: true
        disqusPermalink: "#{config.publicPath}/post/#{request.params.token}"
        disqusIdentifier: request.params.token
        siteDescription: config.siteDescription
        publicPath: config.publicPath

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
          title_bar: "#{config.siteName} - Blog - Page #{pageNum}"
          siteDescription: config.siteDescription
          publicPath: config.publicPath
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
          title_bar: "#{config.siteName} - Blog"
          siteDescription: config.siteDescription
          publicPath: config.publicPath

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
          title_bar: "#{config.siteName} - Blog - Tagged: #{tag} - Page #{page}"
          siteDescription: config.siteDescription
          publicPath: config.publicPath
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
          title_bar: "#{config.siteName} - Blog - Tagged: #{tag}"
          basePath: "/tags/#{tag}/"
          siteDescription: config.siteDescription
          publicPath: config.publicPath
      blog.paginates pagCb, tag
  blog.get_posts pCb, 1, tag

app.get '/rss', (request, response) ->
  pCb = (posts) ->
    blog.attach_bodies posts, (newposts) ->
      response.contentType 'application/xml'
      response.render 'rss',
        "posts": newposts
        title: config.siteName
        path: config.publicPath
        siteDescription: config.siteDescription
        layout: null
        publicPath: config.publicPath
        creator: config.author
  blog.get_posts pCb, 1

app.get '/sitemap.xml', (request, response) ->
  pCb = (posts) ->
    tags = []
    for post in posts
      for tag in post.tags
        if tag not in tags
          tags.push tag
    response.contentType 'application/xml'
    response.render 'sitemap',
      "posts": posts
      layout: null
      publicPath: config.publicPath
      curDate: new Date(Date.now()).toString 'yyyy-MM-dd'
      "tags": tags
  blog.get_posts pCb, -1

app.get '/resume.doc', (request, response) ->
  response.redirect '/resume', '301'

# Read config and listen
start = (err, data) ->
  if err?
    console.log "Error reading config.json."
    throw err
  config = JSON.parse(data.replace "\n", "")
  config.lastFeedUpdate = new Date(Date.now()).toString 'ddd, dd MMM yyyy HH:mm:ss +0000'
  if not config.serverPort?
    throw "No server port defined."
  app.listen config.serverPort
  console.log "Listening on port #{config.serverPort}."
fs.readFile __dirname + '/config.json', 'utf8', start
