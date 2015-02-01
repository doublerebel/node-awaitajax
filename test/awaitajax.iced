Ajax      = require "../lib/awaitajax"
chai      = require "chai"
nock      = require "nock"
should    = chai.should()


createSuccess = (done) ->
  (status, xhr, statusText, data) ->
    if status is "error"
      console.log data
      console.log statusText
    status.should.equal "success"
    data.should.equal "Ok"
    xhr.status.should.equal 200
    done()

testcount = 0


describe "methods", ->
  for method in "getUrl disable queue clearQueue".split " "
    it "should respond to #{method}", ->
      Ajax.should.itself.respondTo method

describe "defaults", ->
  defaults =
    enabled: true
    max: 100
    throttle: 0

  for key, value of defaults
    it "should default #{key} to #{value}", ->
      Ajax[key].should.equal value

describe "url", (next) ->
  scope = undefined
  username = "user"
  password = "test"
  authString = username + ":" + password
  encrypted = new Buffer(authString).toString("base64")
  Ajax.Q::defaults.dataType = 'text/plain'

  mockPlain = (method) ->
    scope = nock("http://www.example.com")[method]("/").reply(200, "Ok")

  mockHttps = (method) ->
    scope = nock("https://www.example.com")[method]("/").reply(200, "Ok")

  mockAuth = (method) ->
    scope = nock("http://www.example.com")[method]("/").matchHeader("authorization", "Basic " + encrypted).reply(200, "Ok")

  testcount += 8

  it "should accept url as property of options object", (done) ->
    mockPlain "get"
    Ajax.awaitGet {url: "http://www.example.com"}, createSuccess done

  it "should parse auth from the url", (done) ->
    mockAuth "get"
    Ajax.awaitGet {url: "http://" + authString + "@www.example.com"}, createSuccess done

  it "should accept auth as property of options object", (done) ->
    mockAuth "get"
    Ajax.awaitGet {
      url: "http://www.example.com"
      auth: authString
    }, createSuccess done

  it "should accept username, password as properties of options object", (done) ->
    mockAuth "get"
    Ajax.awaitGet {
      url: "http://www.example.com"
      username: username
      password: password
    }, createSuccess done

  it "should set port to 443 for https URLs", (done) ->
    mockHttps "get"
    Ajax.awaitGet {url: "https://www.example.com"}, createSuccess done

  it "should set port to the port in the URL string", (done) ->
    scope = nock("http://www.example.com:66").get("/").reply(200, "Ok")
    Ajax.awaitGet {url: "http://www.example.com:66"}, createSuccess done

  it "should set path to the path in the URL string", (done) ->
    scope = nock("http://www.example.com:66").get("/blah").reply(200, "Ok")
    Ajax.awaitGet {url: "http://www.example.com:66/blah"}, createSuccess done

  testcount += 32

  "get post".split(" ").forEach (m) ->
    M = m.toUpperCase()
    Mm = m[0].toUpperCase() + m[1..]

    it "#{M} should accept url as property of options object", (done) ->
      mockPlain m
      Ajax["await#{Mm}"] { url: "http://www.example.com" }, createSuccess done

    it "#{M} should parse auth from the url", (done) ->
      mockAuth m
      Ajax["await#{Mm}"] { url: "http://" + authString + "@www.example.com" }, createSuccess done

    it "#{M} should accept auth as property of options object", (done) ->
      mockAuth m
      Ajax["await#{Mm}"] {
        url: "http://www.example.com"
        auth: authString
      }, createSuccess done

    it "#{M} should accept username, password as properties of options object", (done) ->
      mockAuth m
      Ajax["await#{Mm}"] {
        url: "http://www.example.com"
        username: username
        password: password
      }, createSuccess done

    it "#{M} should set port to 443 for https URLs", (done) ->
      mockHttps m
      Ajax["await#{Mm}"] {url: "https://www.example.com"}, createSuccess done

    it "#{M} should set port to the port in the URL string", (done) ->
      scope = nock("http://www.example.com:66")[m]("/").reply(200, "Ok")
      Ajax["await#{Mm}"] {url: "http://www.example.com:66"}, createSuccess done

    it "#{M} should set path to the path in the URL string", (done) ->
      scope = nock("http://www.example.com:66")[m]("/blah").reply(200, "Ok")
      Ajax["await#{Mm}"] {url: "http://www.example.com:66/blah"}, createSuccess done