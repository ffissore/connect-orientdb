# connect-orientdb
# Copyright(c) 2012 Federico Fissore <federico@fissore.org>
# MIT Licensed

orient = require "orientdb"
connect = require "connect"

default_options =
  host: "localhost"
  port: 2424
  database: "sessions"
  class_name: "Session"
  user_name: "admin"
  user_password: "admin"

class OrientDBStore extends connect.session.Store

  constructor: (options, callback) ->
    options = options or {}

    database = options.database || default_options.database
    
    server = new orient.Server
      host: options.host or default_options.host
      port: options.port or default_options.port
    @db = new orient.Db database, server,
      user_name: options.user_name or default_options.user_name
      user_password: options.user_password or default_options.user_password
    @class_name = options.class_name or default_options.class_name

    @db.open (err) =>
      return callback(err) if err?

      cluster = @db.getClusterByClass @class_name
      return callback(null, @) if cluster?

      @db.createClass @class_name, (err) =>
        return callback(err) if err?

        @db.command "CREATE PROPERTY #{@class_name}.sid STRING", (err) =>
          return callback(err) if err?

          @db.command "CREATE INDEX #{@class_name}.sid UNIQUE", (err) =>
            return callback(err) if err?

            @db.reload (err) =>
              return callback(err) if err?

              callback(null, @)

  load_session_doc = (self, sid, callback) ->
    self.db.command "SELECT FROM #{self.class_name} WHERE sid = '#{sid}'", (err, results) =>
      return callback(err) if err?
      if results.length > 0
        callback(null, results[0])
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
      session_doc.session = session
      session_doc.sid = sid

      if session.cookie && session.cookie._expires
        session_doc.expires = new Date(session.cookie._expires)

      @db.save(session_doc, callback)

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

module.exports = OrientDBStore