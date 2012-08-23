[![build status](https://secure.travis-ci.org/ffissore/connect-orientdb.png)](http://travis-ci.org/ffissore/connect-orientdb)
# connect-orientdb

  [OrientDB](https://code.google.com/p/orient/) session store for Connect (or Connect based, like Express)  
  Code is a CoffeeScript port to OrientDB from [connect-mongo](https://github.com/kcbanner/connect-mongo)

## Installation

via npm:

    $ npm install connect-orientdb

## Options

  - `server.host` OrientDB server hostname (optional, default: "localhost")
  - `server.port` OrientDB server port (optional, default: 2424)
  - `db.user_name` username (optional, default: "admin")
  - `db.user_password` password (optional, default: "admin")
  - `database` Database name (optional, default: "sessions")
  - `class_name` Class name of the session document (optional, default: "Session")

The second parameter to the `OrientDBStore` constructor is a callback which will be called once the database connection is established.
This is mainly used for the tests, however you can use this callback if you want to wait until the store has connected before
starting your app.

## Example

With express:

    var express = require('express');
    var OrientDBStore = require('connect-orientdb')(express);

    var settings = {
        server: {
            host: "localhost",
            port: 2424
        },
        db: {
            user_name: "admin",
            user_password: "admin"
        },
        database: "sessions",
        class_name: "Session"
    };

    app.use(express.session({
        secret: settings.cookie_secret,
        store: new OrientDBStore(settings)
      }));

With connect:

    var connect = require('connect');
    var OrientDBStore = require('connect-orientdb')(connect);


## Tests

connect-orientdb uses `mocha`. Install the dependencies with

    npm install -d
    
then run the tests with

    npm test

The tests expects to find an in memory database called `temp`.

## License 

(The MIT License)

Copyright (c) 2012 Federico Fissore &lt;federico^AT_fissore.org&gt;

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.