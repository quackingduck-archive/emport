# emport.js

A module-like packaging system for javascript and coffeescript source files
that target the browser.

**Don't use this. Use [browserify](https://github.com/substack/node-browserify)**

The idea here was to build a front-end module system that had no run-time (only build-time) dependencies. It seemed like a good idea, the new version of browserify seems like a better idea.

This build process:

```shell
echo "module.exports = 'oh hai'" > module-that-cant-be-used-in-browser.js
echo "alert(require('./cant-be-used-in-browser.js'))" > app-that-wont-work-in-browser.js
browserify app-that-wont-work-in-browser.js > bundled-app-for-browser.js
echo "<script src=bundled-app-for-browser.js></script>" > app.html
open app.html
```

Adds 531 total bytes of overhead. Seems worth it for the ability to use the node/common.js module system.
