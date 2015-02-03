# awaitajax

[![Build Status][ci-master]][travis-ci]
[![Coverage Status][coverage-master]][coveralls]
[![Dependency Status][dependency]][david]
[![devDependency Status][dev-dependency]][david]
[![Downloads][downloads]][npm]

Turns Node `http.request` into single-callback form, for use with await/defer

### What?

Iced CoffeeScript and tamejs offer the await/defer construct that lends itself well to the node-style async pattern `callback(err, response)`, particularly when using a construct like `make_esc` from [iced error](https://github.com/maxtaco/iced-error).

**awaitajax** lets you have your await and easy `jQuery.ajax()`
-style options too. By building on [najax](https://github.com/control/control-najax) http calls can be easily handled in one line.

### Background and related modules

**awaitajax** started as a great exercise in using `iced.Rendezvous()` and `iced.Pipeliner()`, the first-callback-wins and serial-call helper features of Iced.  The [original version](https://github.com/doublerebel/tiger/blob/master/src/tiger.awaitajax.coffee) was created for [TigerJS](https://github.com/doublerebel/tiger), an MVC framework for cross-platform Titanium mobile apps built in JavaScript/CoffeeScript.  Now I can't live without this pattern in node, mobile apps, and the browser.

### Example

Regular
```coffee
await Ajax.awaitGet {url: "https://www.google.com"}, defer err, response
```

Serial
```coffee
await Ajax.awaitQueuedGet {url: "https://www.google.com"}, defer err, response
await Ajax.awaitQueuedGet {url: "http://siteaftergoogle.com"}, defer err, response
```


### License

Copyright 2014-2015 Charles Phillips

MIT Licensed


  [ci-master]: https://img.shields.io/travis/doublerebel/node-awaitajax/master.svg?style=flat-square
  [travis-ci]: https://travis-ci.org/doublerebel/node-awaitajax
  [coverage-master]: https://img.shields.io/coveralls/doublerebel/node-awaitajax/master.svg?style=flat-square
  [coveralls]: https://coveralls.io/r/doublerebel/node-awaitajax
  [dependency]: https://img.shields.io/david/doublerebel/node-awaitajax.svg?style=flat-square
  [david]: https://david-dm.org/doublerebel/node-awaitajax
  [dev-dependency]: https://img.shields.io/david/dev/doublerebel/node-awaitajax.svg?style=flat-square
  [david-dev]: https://david-dm.org/doublerebel/node-awaitajax#info=devDependencies
  [downloads]: https://img.shields.io/npm/dm/awaitajax.svg?style=flat-square
  [npm]: https://www.npmjs.org/package/awaitajax
