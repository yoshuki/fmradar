package classes {
  import air.net.URLMonitor
  import air.update.ApplicationUpdaterUI

  import flash.data.SQLConnection
  import flash.data.SQLStatement
  import flash.display.NativeMenu
  import flash.errors.SQLError
  import flash.utils.Timer

  import mx.formatters.DateFormatter

  public class FMR {
    public static const FM_RSS_URL_EXP:String = '^http://www\\.freshmeeting\\.com/personalrss\\.php\\?r=[0-9a-z]+$'
//    public static const FM_RSS_URL_EXP:String = '^http://.+$'
    public static const FM_URL:String = 'http://www.freshmeeting.com/'

    public static var appName:String
    public static var appVersion:String

    public static var configs:Object = {}
    public static var numOpenedMessages:int = 0

    private static var _appUpdater:ApplicationUpdaterUI
    private static var _configWindow:ConfigWindow
    private static var _displayManager:DisplayManager
    private static var _iconMenu:NativeMenu
    private static var _urlMonitor:URLMonitor
    private static var _updateTimer:Timer
    private static var _sqlConnection:SQLConnection

    public static function set appUpdater(updater:ApplicationUpdaterUI):void {
      _appUpdater = updater
    }
    public static function get appUpdater():ApplicationUpdaterUI {
      return _appUpdater
    }

    public static function set configWindow(window:ConfigWindow):void {
      _configWindow = window
    }
    public static function get configWindow():ConfigWindow {
      return _configWindow
    }

    public static function set displayManager(manager:DisplayManager):void {
      _displayManager = manager
    }
    public static function get displayManager():DisplayManager {
      return _displayManager
    }

    public static function set iconMenu(menu:NativeMenu):void {
      _iconMenu = menu
    }
    public static function get iconMenu():NativeMenu {
      return _iconMenu
    }

    public static function set urlMonitor(monitor:URLMonitor):void {
      _urlMonitor = monitor
    }
    public static function get urlMonitor():URLMonitor {
      return _urlMonitor
    }

    public static function set updateTimer(timer:Timer):void {
      _updateTimer = timer
    }
    public static function get updateTimer():Timer {
      return _updateTimer
    }

    public static function set sqlConnection(conn:SQLConnection):void {
      _sqlConnection = conn
    }
    public static function get sqlConnection():SQLConnection {
      return _sqlConnection
    }

    public static function escapeHTML(html:String):String {
      return html.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;').replace("'", '&apos;')
    }

    public static function initializeDb(version:int=0):Boolean {
      var stmt:SQLStatement = new SQLStatement()
      stmt.sqlConnection = sqlConnection

      switch (version) {
      case 0:
        // schema_info
        stmt.text = 'DROP TABLE IF EXISTS schema_info'
        stmt.execute()
        stmt.text = 'CREATE TABLE schema_info (version INTEGER)'
        stmt.execute()
        stmt.text = 'INSERT INTO schema_info (version) VALUES (2)'
        stmt.execute()

        // configs
        stmt.text = 'DROP TABLE IF EXISTS configs'
        stmt.execute()
        stmt.text = 'CREATE TABLE configs (id INTEGER PRIMARY KEY, rss_url TEXT, update_interval INTEGER DEFAULT 60, display_time INTEGER DEFAULT 10)'
        stmt.execute()
        stmt.text = "INSERT INTO configs (rss_url) VALUES ('')"
        stmt.execute()

        // updated_rooms
        stmt.text = 'DROP TABLE IF EXISTS updated_rooms'
        stmt.execute()
        stmt.text = 'CREATE TABLE updated_rooms (id INTEGER PRIMARY KEY, url TEXT, name TEXT, last_update TEXT, updated_at TEXT)'
        stmt.execute()
        break
      case 1:
        // 通知の表示時間を追加
        stmt.text = 'ALTER TABLE configs ADD COLUMN display_time INTEGER DEFAULT 10'
        stmt.execute()
        stmt.text = 'UPDATE schema_info SET version = 2'
        stmt.execute()
        break
      }

      return true
    }

    public static function loadConfigs():Boolean {
      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'SELECT id, rss_url, update_interval, display_time FROM configs ORDER BY id DESC LIMIT 1'
        stmt.execute()

        var rows:Array = stmt.getResult().data
        if (rows !== null) {
          configs.id = rows[0]['id']
          configs.rssUrl = rows[0]['rss_url']
          configs.updateInterval = rows[0]['update_interval']
          configs.displayTime = rows[0]['display_time']
        }
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
        return false
      }

      return true
    }

    public static function saveRssUrl(rssUrl:String):Boolean {
      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'UPDATE configs SET rss_url = @rssUrl WHERE id = @id'
        stmt.parameters['@rssUrl'] = rssUrl
        stmt.parameters['@id'] = configs.id
        stmt.execute()

        configs.rssUrl = rssUrl
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
        return false
      }

      return true
    }

    public static function saveUpdateInterval(updateInterval:int):Boolean {
      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'UPDATE configs SET update_interval = @updateInterval WHERE id = @id'
        stmt.parameters['@updateInterval'] = updateInterval
        stmt.parameters['@id'] = configs.id
        stmt.execute()

        configs.updateInterval = updateInterval
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
        return false
      }

      return true
    }

    public static function saveDisplayTime(displayTime:int):Boolean {
      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'UPDATE configs SET display_time = @displayTime WHERE id = @id'
        stmt.parameters['@displayTime'] = displayTime
        stmt.parameters['@id'] = configs.id
        stmt.execute()

        configs.displayTime = displayTime
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
        return false
      }

      return true
    }

    public static function loadUpdatedRooms():Array {
      var rooms:Array = []

      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'SELECT url, name, last_update, updated_at FROM updated_rooms ORDER BY updated_at DESC'
        stmt.execute()

        var rows:Array = stmt.getResult().data
        if (rows !== null) {
          for each (var row:Object in rows) {
            rooms.push(row)
          }
        }
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
      }

      return rooms
    }

    public static function loadUpdatedRoom(url:String):Object {
      var room:Object = {}

      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'SELECT id, url, name, last_update, updated_at FROM updated_rooms WHERE url = @url'
        stmt.parameters['@url'] = url
        stmt.execute()

        var rows:Array = stmt.getResult().data
        if (rows !== null) {
          room.id         = rows[0]['id']
          room.url        = rows[0]['url']
          room.name       = rows[0]['name']
          room.lastUpdate = rows[0]['last_update']
          room.updatedAt  = rows[0]['updated_at']
        }
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
      }

      return room
    }

    public static function saveUpdatedRoom(room:Object):Boolean {
      try {
        var stmt:SQLStatement = new SQLStatement()
        stmt.sqlConnection = sqlConnection

        stmt.text = 'SELECT id FROM updated_rooms WHERE url = @url'
        stmt.parameters['@url'] = room.url
        stmt.execute()

        var rows:Array = stmt.getResult().data
        stmt.clearParameters()

        var df:DateFormatter = new DateFormatter()
        df.formatString = 'YYYYMMDDJJNNSS'

        if (rows !== null) {
          stmt.text = 'UPDATE updated_rooms SET last_update = @lastUpdate, updated_at = @updatedAt WHERE id = @id'
          stmt.parameters['@lastUpdate'] = room.lastUpdate
          stmt.parameters['@updatedAt'] = df.format(new Date())
          stmt.parameters['@id'] = rows[0]['id']
        } else {
          stmt.text = 'INSERT INTO updated_rooms (url, name, last_update, updated_at) VALUES (@url, @name, @lastUpdate, @updatedAt)'
          stmt.parameters['@url'] = room.url
          stmt.parameters['@name'] = room.name
          stmt.parameters['@lastUpdate'] = room.lastUpdate
          stmt.parameters['@updatedAt'] = df.format(new Date())
        }

        stmt.execute()
      } catch (error:SQLError) {
        trace('error.message:', error.message)
        trace('error.details:', error.details)
        return false
      }

      return true
    }
  }
}
