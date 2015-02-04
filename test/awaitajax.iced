Ajax      = require "../lib/awaitajax"
chai      = require "chai"
nock      = require "nock"
should    = chai.should()


testurl  = "www.example.com"
httpurl  = "http://#{testurl}"
httpsurl = "https://#{testurl}"

createSuccess = (done, statusCode = 200) ->
  (status, xhr, statusText, data) ->
    if status is "error"
      console.log data
      console.log statusText
    status.should.equal "success"
    data.should.equal "Ok"
    xhr.status.should.equal 200
    done()

createError = (done, statusCode = 404) ->
  (status, xhr, statusText, data) ->
    if status is "success"
      console.log data
      console.log statusText
    status.should.equal "error"
    xhr.status.should.equal statusCode
    done()

testcount = 0


describe "Ajax object", ->

  describe "Ajax.methods", ->
    for method in "getURL disable queue clearQueue".split " " then do (method) ->
      it "should respond to #{method}", ->
        Ajax.should.itself.respondTo method

  describe "Ajax.defaults", ->
    defaults =
      enabled: true
      max: 100
      throttle: 0

    for key, value of defaults then do (key, value) ->
      it "should default #{key} to #{value}", ->
        Ajax[key].should.equal value

  describe "Ajax.getURL", ->
    it "should get URL from object.url", ->
      obj = url: httpurl
      url = Ajax.getURL obj
      url.should.equal.httpurl

    it "should get URL from object.url()", ->
      obj = url: -> httpurl
      url = Ajax.getURL obj
      url.should.equal.httpurl

  describe "Ajax.disable", ->
    it "should disable itself while running a callback", (next) ->
      Ajax.disable ->
        Ajax.enabled.should.be.false
        next()

    it "should catch, throw and re-enable if callback throws an error", ->
      thrower = -> throw new Error
      (Ajax.disable.bind Ajax, thrower).should.throw(Error)
      Ajax.enabled.should.be.true

    it "should run callback immediately if disabled", (next) ->
      Ajax.enabled.should.be.true
      Ajax.enabled = false
      Ajax.disable ->
        Ajax.enabled = true
        next()

  describe "Ajax.queue", ->
    it "should get the queue when called with no arguments", ->
      Ajax.queue().should.be.instanceof Array

  describe "Ajax.clearQueue", ->
    it "should clear the queue", ->
      Ajax.queue().push ->
      Ajax.queue().should.not.be.empty
      Ajax.clearQueue()
      Ajax.queue().should.be.empty


describe "url parsing and basic auth", (next) ->
  scope = undefined
  username = "user"
  password = "test"
  authString = username + ":" + password
  encrypted = new Buffer(authString).toString("base64")
  Ajax.Q::defaults.dataType = 'text/plain'

  mockPlain = (method) ->
    scope = nock(httpurl)[method]("/")
            .reply(200, "Ok")

  mockHttps = (method) ->
    scope = nock(httpsurl)[method]("/")
            .reply(200, "Ok")

  mockAuth = (method) ->
    scope = nock(httpurl)[method]("/")
            .matchHeader("authorization", "Basic " + encrypted)
            .reply(200, "Ok")

  mockFail = (method) ->
    scope = nock(httpurl)[method]("/")
            .reply(404, "Not Found")

  testcount += 14

  "get post".split(" ").forEach (m) ->
    M = m.toUpperCase()
    Mm = m[0].toUpperCase() + m[1..]
    fn = "await#{Mm}"

    it "#{fn} should accept url as property of options object", (done) ->
      mockPlain m
      Ajax[fn] { url: httpurl }, createSuccess done

    it "#{fn} should pass non-success replies as errors", (done) ->
      mockFail m
      Ajax[fn] { url: httpurl }, createError done

    it "#{fn} should parse auth from the url", (done) ->
      mockAuth m
      Ajax[fn] { url: "http://" + authString + "@#{testurl}" }, createSuccess done

    it "#{fn} should accept auth as property of options object", (done) ->
      mockAuth m
      Ajax[fn] {
        url: httpurl
        auth: authString
      }, createSuccess done

    it "#{fn} should accept username, password as properties of options object", (done) ->
      mockAuth m
      Ajax[fn] {
        url: httpurl
        username: username
        password: password
      }, createSuccess done

    it "#{fn} should set port to 443 for https URLs", (done) ->
      mockHttps m
      Ajax[fn] {url: httpsurl}, createSuccess done

    it "#{fn} should set port to the port in the URL string", (done) ->
      scope = nock("#{httpurl}:66")[m]("/").reply(200, "Ok")
      Ajax[fn] {url: "#{httpurl}:66"}, createSuccess done

    it "#{fn} should set path to the path in the URL string", (done) ->
      scope = nock("#{httpurl}:66")[m]("/blah").reply(200, "Ok")
      Ajax[fn] {url: "#{httpurl}:66/blah"}, createSuccess done


    describe "sequential and batch queueing", ->
      qFn  = "awaitQueued#{Mm}"
      data = {a: 2}
      dataString = JSON.stringify data

      mockQueued = (method, times) ->
        if method is "post" then scope = nock(httpurl)[method]("/", data)
        else                     scope = nock(httpurl)[method]("/")
        scope.times(times)
             .delay(Math.floor Math.random() * 20)
             .reply(200, "Ok")

      mockPreHack = (method, times) ->
        if method is "post" then scope = nock(httpurl)[method]("/", data)
        else                     scope = nock(httpurl)[method]("/?#{dataString}")
        scope.times(times)
             .delay(Math.floor Math.random() * 50)
             .reply(200, "Ok")

      it "#{qFn} should accept url as property of options object", (done) ->
        mockPlain m
        Ajax[qFn] { url: httpurl }, createSuccess done

      it "#{qFn} should pass non-success replies as errors", (done) ->
        mockFail m
        Ajax[qFn] { url: httpurl }, createError done

      it "#{qFn} should sequentially queue multiple calls", (done) ->
        delete Ajax.pipeliner
        Ajax.max = 1
        calls    = 20
        range    = [1..calls]
        basket   = []
        options  =
          url: httpurl
          processData: true
        options.data = data if m is "post"

        mockQueued m, calls
        await
          for i in range then do (i, deferred = defer()) ->
            await Ajax[qFn] options, defer status
            status.should.equal "success"
            basket.push i
            deferred()

        basket[i-1].should.equal range[i-1] for i in range
        Ajax.max = 100
        done()

      it "#{qFn} should batch queue multiple calls in sets", (done) ->
        delete Ajax.pipeliner
        max      = 5
        Ajax.max = max
        calls    = 20
        range    = [1..calls]
        live     = 0
        options  =
          url: httpurl
          processData: true
          contentType: "text/json"

        class Fake
          toString: ->
            live++
            live.should.be.at.most max
            dataString
        options.data = new Fake

        mockPreHack m, calls
        await
          for i in range then do (deferred = defer()) ->
            await Ajax[qFn] options, defer status
            status.should.equal "success"
            live--
            deferred()

        Ajax.max = 100
        done()
