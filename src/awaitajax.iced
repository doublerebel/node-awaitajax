Ajax  = require "./ajax"


extend = (target, sources...) ->
  target[key] = val for key, val of source for source in sources
  target


awaitAjax =
  awaitAjax: (options, cb, queue = false) ->
    rv = new iced.Rendezvous()

    options.success = rv.id('success').defer data, statusText, xhr # data, statusText, xhr
    options.error   = rv.id('error').defer xhr, statusText, data # xhr, statusText, error

    q = new @Q
    if queue then q.ajaxQueue options
    else q.ajax options

    await rv.wait defer status
    cb status, xhr, statusText, data

  awaitGet: (options, cb, queue) ->
    options.type = 'GET'
    @awaitAjax options, cb, queue

  awaitPost: (options, cb, queue) ->
    options.type = 'POST'
    @awaitAjax options, cb, queue

  awaitQueuedAjax: (options, cb) ->
    @awaitAjax options, cb, true

  awaitQueuedGet: (options, cb) ->
    @awaitGet options, cb, true

  awaitQueuedPost: (options, cb) ->
    @awaitPost options, cb, true


module.exports = extend {}, Ajax, awaitAjax