md = (require 'markdown').Markdown
fs = require 'fs'
async = require 'async'


class Article

  constructor: (@filename, @title, @post_date, @tags) ->

  render: (callback) ->
    fs.readFile @filename, 'utf8', (err, data) ->
      if err
        throw err
      callback md data

settings =
  "article path": './articles'
  "article index": './article_index.json'

exports.set = (parameter, value) ->
  settings[parameter] = value

md_pattern = new RegExp /(.markdown$|.md$)/i

is_article = (path, callback) ->
  fs.stat path, (stats) ->
    callback stats.isFile() and md_pattern.test path

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
      throw err
    iter2 = (item, cb) ->
      fs.readFile "#{settings['article path']}/#{item}", 'utf8', (err, data) ->
        if err
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
        throw err
      artsort = (a, b) ->
        return a > b
      artobjs = artobjs.sort artsort
      indexjson = JSON.stringify artobjs
      fs.writeFile settings['article index'], indexjson, (err) ->
        if err
          throw err
        callback(true)
