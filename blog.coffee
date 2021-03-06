md = (require 'node-markdown').Markdown
fs = require 'fs'
async = require 'async'
datejs = require 'datejs'

class Article

  constructor: (@filename, @title, @post_date, @tags) ->

  niceDate: (format='MMMM dS, yyyy') ->
    (new Date @post_date).toString format

  rssDate: ->  @niceDate 'ddd, dd MMM yyyy HH:mm:ss +0000'
  modDate: =>  @niceDate 'yyyy-MM-dd'

  token: () ->
    v = @filename.split '.'
    v[0..v.length - 2].join '-'

  filePart: () ->
    v = @filename.split '.'
    v[0..v.length - 2].join '.'

  cachedName: () ->
    cacheName = @filename.split '.'
    cacheName = (cacheName[0..cacheName.length - 2].join '.') + '.html'
    "#{settings['cache']}/#{cacheName}"

  render: (callback) ->
    apath = "#{settings['article path']}/#{@filename}"
    fs.readFile apath, 'utf8', (err, data) ->
      if err?
        throw err
      if data?
        data = data.split "\n\n"
        data = data[1..data.length - 1].join "\n\n"
        callback md data

  cached: (callback) ->
    fs.readFile @cachedName(), 'utf8', (err, data) ->
      if err?
        throw err
      if data?
        callback data


exports.attach_body = (post, callback) ->
  post.cached (data) ->
    post.body = data
    callback post

exports.attach_bodies = (posts, callback) ->
  pIter = (post, cb) ->
    post.cached (body) ->
      post.body = body
      cb()
  async.forEach posts, pIter, (err) ->
    if err?
      throw err
    callback posts

settings =
  "article path": __dirname + '/articles'
  "article index": __dirname + '/article_index.json'
  "posts per page": 5
  "cache": __dirname + '/cache'
exports.settings = settings

load_index = (callback, tag) ->
  fs.readFile settings['article index'], 'utf8', (err, data) ->
    if err?
      exports.generate_index (res) ->
        if res
          load_index callback
    else
      posts = JSON.parse line for line in data.toString().split "\n"
      hasTag = (item) ->
        item.tags? and tag in item.tags
      if tag?
        posts = posts.filter hasTag
      callback posts

all_tags = (callback) ->
  pCb = (posts) ->
    tags = []
    for post in posts
      for tag in post.tags
        if tag not in tags
          tags.push tag
    callback tags
  exports.get_posts pCb, -1


exports.paginates = (callback, pagenum=1, tag) ->
  liCb = (posts) ->
    next = false
    prev = false
    pp = settings['posts per page']
    if posts.length > pp and pp*(pagenum-1) + pp < posts.length
      next = true
    if pagenum > 1
      prev = true
    callback [next, prev]
  load_index liCb, tag

exports.get_posts = (callback, pagenum=1, tag) ->
  pp = settings["posts per page"]
  liCb = (index) ->
    if pagenum != -1
      index = index[pp*(pagenum-1)...pp*(pagenum)-1]
    articles = []
    for art in index
      if art.filename? and art.title? and art.post_date?
        if art.tags == null
          art.tags = []
        articles.push new Article art.filename, art.title, art.post_date, art.tags
    callback articles
  load_index liCb, tag

exports.get_post = (token, callback) ->
  load_index (index) ->
    fillCb = (item) ->
      firstPart = (item.filename.split '.')[0]
      firstPart == token
    res = index.filter fillCb
    if res.length == 0
      return null
    res = res[0]
    if res.filename? and res.title? and res.post_date?
      if not res.tags?
        res.tags = []
      callback new Article res.filename, res.title, res.post_date, res.tags

exports.set = (parameter, value) ->
  settings[parameter] = value

md_pattern = new RegExp /(.markdown$|.md$)/i

is_article = (path, callback) ->
  fs.stat path, (stats) ->
    callback stats.isFile() and md_pattern.test path

get_comment = (text) ->
  if text[0..3] != '<!--'
    throw "First line in post must be an HTML comment."
  text = text[4...text.length]
  ouch = text.split '-->'
  jsonBody = ouch[0]
  postBody = ouch[1...ouch.length].join '-->'
  [jsonBody, postBody]

exports.build_cache = (callback) ->
  iter = (item, cb) ->
    np = "#{settings['cache']}/#{item}"
    if (fs.statSync np).isFile
      fs.unlinkSync np
    cb()
  currentCache = fs.readdirSync settings['cache']
  async.forEach currentCache, iter, (err) ->
    if err?
      console.log "Error while removing previous cache."
      throw err
    exports.generate_index (result) ->
      exports.get_posts (posts) ->
        wIter = (item, cb) ->
          htmlFilename = item.filename.split '.'
          htmlFilename = htmlFilename[0..htmlFilename.length - 2].join '.'
          htmlFilename = htmlFilename + '.html'
          item.render (data) ->
            cacheFile = "#{settings['cache']}/#{htmlFilename}"
            fs.writeFile cacheFile, data, 'utf8', (err) ->
              if err?
                throw err
              cb()
        async.forEach posts, wIter, (err) ->
          if err?
            throw err
          callback true

exports.generate_index = (callback) ->
  try
    fs.unlinkSync settings['article index']
  catch err

  articles = []
  artobjs = []
  iter = (item, cb) ->
    if (fs.statSync "#{settings['article path']}/#{item}").isFile and md_pattern.test item
      articles.push item
    cb()
  particles = fs.readdirSync settings['article path']
  async.forEach particles, iter, (err) ->
    if err?
      console.log "Error while parsing article sources:"
      throw err
    iter2 = (item, cb) ->
      fs.readFile "#{settings['article path']}/#{item}", 'utf8', (err, data) ->
        if err?
          console.log "Error while reading article source."
          throw err
        [jsonBody, body] = get_comment(data)
        header = JSON.parse jsonBody
        artobjs.push new Article item, header.title, (Date.parse header.post_date), header.tags
        cb()
    async.forEach articles, iter2, (err) ->
      if err?
        console.log "Error while building articles."
        throw err
      artsort = (a, b) ->
        return a.post_date > b.post_date
      artobjs = artobjs.sort artsort
      artobjs.reverse()
      indexjson = JSON.stringify artobjs
      fs.writeFile settings['article index'], indexjson, (err) ->
        if err?
          console.log "Error while building article index."
          throw err
        callback(true)
