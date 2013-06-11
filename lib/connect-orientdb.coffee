# connect-orientdb
# Copyright(c) 2012 Federico Fissore <federico@fissore.org>
# MIT Licensed

orient = require "orientdb"

TEN_MINUTES = 10 * 60 * 1000
TWO_HOURS = 2 * 60 * 60 * 1000

default_options =
  server:
    host: "localhost"
    port: 2424
  db:
    user_name: "admin"
    user_password: "admin"
  database: "sessions"
  class_name: "Session"
  reap_interval: TEN_MINUTES

module.exports = (connect) ->
  class OrientDBStore extends connect.session.Store

    constructor: (options, callback) ->
      callback = callback or ->

      options = options or {}
      options.server = options.server or {}
      options.db = options.db or {}
      options.server.host = options.server.host or default_options.server.host
      options.server.port = options.server.port or default_options.server.port
      options.db.user_name = options.db.user_name or default_options.db.user_name
      options.db.user_password = options.db.user_password or default_options.db.user_password

      server = new orient.Server options.server

      @db = new orient.Db (options.database || default_options.database), server, options.db

      @class_name = options.class_name or default_options.class_name

      @db.open (err) =>
        return callback(err) if err?

        cluster = @db.getClusterByClass @class_name
        return callback(null, @) if cluster?

        @db.createClass @class_name, (err) =>
          return callback(err) if err?

          @db.command "CREATE PROPERTY #{@class_name}.sid STRING", (err) =>
            return callback(err) if err?

            @db.command "ALTER PROPERTY #{@class_name}.sid MANDATORY true", (err) =>
              return callback(err) if err?

              @db.command "ALTER PROPERTY #{@class_name}.sid NOTNULL true", (err) =>
                return callback(err) if err?

                @db.command "CREATE INDEX #{@class_name}.sid UNIQUE", (err) =>
                  return callback(err) if err?

                  @db.reload (err) =>
                    return callback(err) if err?

                    if options.reap_interval > 0
                      setInterval(@reap_expired, options.reap_interval)

                    callback(null, @)

    load_session_doc = (self, sid, callback) ->
      self.db.command "SELECT FROM index:#{self.class_name}.sid WHERE key = '#{sid}'", { fetchPlan: "*:-1" }, (err, results) =>
        return callback(err) if err?
        if results.length > 0
          callback(null, results[0].rid)
        else
          callback()

    get: (sid, callback) ->
      load_session_doc @, sid, (err, session_doc) =>
        return callback(err) if err?
        return callback() if !session_doc

        if !session_doc.expires or new Date() < session_doc.expires
          callback(null, session_doc.session)
        else
          @destroy(sid, callback)

    set: (sid, session, callback) ->
      load_session_doc @, sid, (err, session_doc) =>
        session_doc = session_doc || {}
        session_doc["@class"] = session_doc["@class"] or @class_name
        session_doc.sid = sid
        session_doc["@version"] = -1

        if session.cookie && session.cookie._expires
          session_doc.expires = new Date(session.cookie._expires)
        else if session.cookie? and typeof session.cookie.maxAge is "number"
          session_doc.expires = new Date(+new Date() + session.cookie.maxAge)
        else
          session_doc.expires = new Date(+new Date() + (TWO_HOURS))

        session_doc.session = JSON.parse(JSON.stringify(session))
        @db.save session_doc, (err, session_doc) ->
          return callback(err) if err?
          callback(null, session_doc.session)

    destroy: (sid, callback) ->
      load_session_doc @, sid, (err, session_doc) =>
        @db.delete session_doc, callback

    length: (callback) ->
      clusterName = @db.getClusterByClass(@class_name).name
      @db.countRecordsInCluster clusterName, callback

    clear: (callback) ->
      @db.command "DELETE FROM #{@class_name}", callback

    close: (callback) ->
      @db.close callback

    reap_expired: (callback) =>
      @db.command "DELETE FROM #{@class_name} WHERE expires < #{new Date()}", callback

  return OrientDBStore