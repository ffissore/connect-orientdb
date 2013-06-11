connect = require("connect")
OrientDBStore = require("../index")(connect)
assert = require("assert")

options =
  database: "temp"
  reap_interval: 100

exports.test_set = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set-sid"
    session =
      foo: "bar"
    store.set sid, session, (err, session) ->
      assert.strictEqual err, null

      store.db.command "select from Session where sid = '#{sid}'", (err, results) ->
        assert.equal sid, results[0].sid
        assert.equal "bar", results[0].session.foo

        store.clear ->
          done()

exports.test_set_expires = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set_expires-sid"
    data =
      foo: "bar"
      cookie:
        _expires: "2011-04-26T03:10:12.000Z"

    store.set sid, data, (err, session) ->
      assert.strictEqual err, null

      store.db.command "select from Session where sid = '#{sid}'", (err, results) ->
        assert.equal sid, results[0].sid
        assert.equal "bar", results[0].session.foo
        assert.equal(results[0].expires.toJSON(), new Date(data.cookie._expires).toJSON())

        store.clear ->
          done()

exports.test_set_get = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set-sid"
    session =
      foo: "bar"
    store.set sid, session, (err, session) ->
      assert.strictEqual err, null

      store.get sid, (err, session) ->
        assert.equal "bar", session.foo

        store.clear ->
          done()

exports.test_set_length = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set-sid"
    session =
      foo: "bar"
    store.set sid, session, (err, session) ->
      assert.strictEqual err, null

      store.length (err, count) ->
        assert.equal 1, count

        store.clear ->
          done()

exports.test_set_destroy = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set-sid"
    session =
      foo: "bar"
    store.set sid, session, (err, session) ->
      assert.strictEqual err, null

      store.destroy sid, (err) ->
        assert.strictEqual err, null

        store.clear ->
          done()

exports.test_set_length_clear = (done) ->
  new OrientDBStore options, (err, store) ->
    sid = "test_set-sid"
    session =
      foo: "bar"
    store.set sid, session, (err, session) ->
      assert.strictEqual err, null

      store.length (err, count) ->
        assert.equal 1, count

        store.clear ->
          store.length (err, count) ->
            assert.equal 0, count

            done()

exports.test_load = (done) ->
  this.timeout(0)
  new OrientDBStore options, (err, store) ->
    sid = "test_load-sid"
    data =
      foo: "bar"
      cookie:
        _expires: new Date()

    store.set sid, data, (err, session) ->
      number_of_calls = 10000
      number_of_calls_done = 0
      for i in [0...number_of_calls]
        store.set sid, data, (err, session) ->
          number_of_calls_done++
          assert !err?, ["number_of_calls_done #{number_of_calls_done}", err]
          done() if number_of_calls_done is number_of_calls
