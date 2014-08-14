najax       = require "najax"
{Pipeliner} = require "iced-coffee-script/lib/coffee-script/icedlib"


extend = (target, sources...) ->
  target[key] = val for key, val of source for source in sources
  target


Ajax =
  getURL: (object) ->
    object and object.url?() or object.url

  enabled: true

  disable: (callback) ->
    if @enabled
      @enabled = false
      try
        do callback
      catch e
        throw e
      finally
        @enabled = true
    else
      do callback

  max: 100
  throttle: 0

  queue: (request) ->
    @pipeliner or= new Pipeliner @max, @throttle
    return @pipeliner.queue unless request
    await @pipeliner.waitInQueue defer()
    request @pipeliner.defer()

  clearQueue: ->
    @pipeliner.queue = []
    @pipeliner.n_out = 0


class Base
  defaults:
    contentType: 'application/json'
    dataType: 'json'
    processData: false
    headers: {'X-Requested-With': 'XMLHttpRequest'}

  queue: Ajax.queue

  ajax: (params, defaults) ->
    najax @ajaxSettings(params, defaults)

  ajaxQueue: (params, defaults) ->
    xhr = null
    rv  = new iced.Rendezvous

    settings     = @ajaxSettings(params, defaults)
    defersuccess = settings.success
    defererror   = settings.error

    settings.success = rv.id('success').defer data, statusText, xhr
    settings.error   = rv.id('error').defer xhr, statusText, error

    request = (next) ->
      xhr = new Ajax(settings)
      await rv.wait defer status
      switch status
        when 'success' then defersuccess data, statusText, xhr
        when 'error' then defererror xhr, statusText, error
      next()

    request.abort = (statusText) ->
      return xhr.abort(statusText) if xhr
      index = @queue().indexOf(request)
      @queue().splice(index, 1) if index > -1
      Ajax.pipeliner.n_out-- if Ajax.pipeliner

      # deferred.rejectWith(
      #   settings.context or settings,
      #   [xhr, statusText, '']
      # )
      request

    return request unless Ajax.enabled
    @queue request
    request

  ajaxSettings: (params, defaults) ->
    extend({}, @defaults, defaults, params)


# Globals
Ajax.defaults   = Base::defaults
Ajax.Q          = Base
module?.exports = Ajax

