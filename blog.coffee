md = (require 'node-markdown').Markdown
fs = require 'fs'
async = require 'async'


class Article

  constructor: (@filename, @title, @post_date, @tags) ->

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
  "article path": './articles'
  "article index": './article_index.json'
  "posts per page": 20
  "cache": './cache'

load_index = (callback) ->
  fs.readFile settings['article index'], 'utf8', (err, data) ->
    if err?
      exports.generate_index (res) ->
        if res
          load_index callback
    else
      callback JSON.parse line for line in data.toString().split "\n"

exports.get_posts = (callback, pagenum=1) ->
  pp = settings["posts per page"]
  load_index (index) ->
    console.log index.toString()
    if pagenum != -1
      index = index[pp*(pagenum-1)..pp*(pagenum)]
    console.log "Index: #{index}"
    articles = []
    for art in index
      console.log "File status: #{art.filename?} #{art.title?} #{art.post_date?} #{art.tags?}"
      if art.filename? and art.title? and art.post_date?
        if not art.tags?
          art.tags = []
        articles.push new Article art.filename, art.title, art.post_date, art.tags
    console.log "pushing back articles"
    console.log articles
    callback articles

exports.get_post = (token, callback) ->
  load_index (index) ->
    console.log index.toString()
    filCb = (item) ->
      firstPart = (item.filename.split '.')[0]
      firstPart == token
    res = index.filter fillCb
    if res.length == 0
      return null
    res = res[0]
    if res.filename? and res.title? and res.post_date?
      if not art.tags?
        art.tags = []
      callback new Article res.filename, res.title, res.post_date, res.tags

exports.set = (parameter, value) ->
  settings[parameter] = value

md_pattern = new RegExp /(.markdown$|.md$)/i

is_article = (path, callback) ->
  fs.stat path, (stats) ->
    callback stats.isFile() and md_pattern.test path

exports.build_cache = (callback) ->
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
    if err
      console.log "Error while parsing article sources:"
      throw err
    iter2 = (item, cb) ->
      fs.readFile "#{settings['article path']}/#{item}", 'utf8', (err, data) ->
        if err
          console.log "Error while reading article source."
          throw err
        splot = data.split "\n\n"
        body = (splot[1..splot.length]).join "\n\n"
        headertext = splot[0]
        headertext.replace "\n", ""
        header = JSON.parse headertext
        artobjs.push new Article item, header.title, Date.parse header.post_date, header.tags
        cb()
    async.forEach articles, iter2, (err) ->
      if err
        console.log "Error while building articles."
        throw err
      artsort = (a, b) ->
        return a > b
      artobjs = artobjs.sort artsort
      indexjson = JSON.stringify artobjs
      fs.writeFile settings['article index'], indexjson, (err) ->
        if err
          console.log "Error while building article index."
          throw err
        callback(true)
