url = require 'url'

SNORMAL = 0
SQUOTE = 1

exports.parseTerms = parseTerms = (termsText) ->
  state = SNORMAL
  terms = []
  curChar = ''
  curWord = ''
  offset = 0
  while true
    curChar = termsText[offset]
    if not curChar?
      if curWord != ''
        terms.push curWord
      break
    switch state
      when SNORMAL
        switch curChar
          when '"'
            state = SQUOTE
          when '(', ')'
            offset++
            continue
          when ' ', undefined
            if curWord != ''
              terms.push curWord
            curWord = ''
          else
            curWord += curChar
      when SQUOTE
        switch curChar
          when '"', undefined
            state = SNORMAL
            if curWord != ''
              terms.push curWord
            curWord = ''
          else
            curWord += curChar
    offset++
    continue
  outTerms = []
  for term in terms
    if term not in outTerms and term.length > 3
      outTerms.push term
  return outTerms

exports.searchTerms = searchTerms = (request, debug) ->
  fulref = request.header 'Referer'
  ref = request.header 'Referer'
  debug = debug? and debug
  if not ref?
    return null
  purl = url.parse ref, true
  if ('google.com' in purl.hostname and purl.pathname == '/search') or debug
    stxt = purl.query.q
    terms = parseTerms stxt
    return terms
  else
    return null

