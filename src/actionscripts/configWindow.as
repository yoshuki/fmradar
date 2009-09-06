import classes.FMR

import flash.desktop.NativeApplication
import flash.events.KeyboardEvent
import flash.events.MouseEvent

private function initCW(cw:ConfigWindow):void {
  if (!loadConfigs(cw)) {
    trace('Failed to open configs.')
    cw.close()
  }

  cw.stage.focus = cw.rssUrl
  cw.addEventListener(Event.CLOSE, function (event:Event):void {
    FMR.configWindow = null
  })

  // 出来る限りリアルタイム（フォーカスが外れたとき以外）でバリデートする。
  cw.rssUrl.addEventListener(KeyboardEvent.KEY_UP, function (event:KeyboardEvent):void {
    cw.rssUrlValidator.validate()
  })
  cw.rssUrl.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
    cw.rssUrlValidator.validate()
  })
  cw.rssUrl.addEventListener(MouseEvent.RIGHT_CLICK, function (event:MouseEvent):void {
    cw.rssUrlValidator.validate()
  })
}

private function loadConfigs(cw:ConfigWindow):Boolean {
  if (FMR.loadConfigs()) {
    cw.rssUrl.text = FMR.configs.rssUrl
    cw.updateInterval.value = FMR.configs.updateInterval
    cw.displayTime.value = FMR.configs.displayTime
    cw.autoStart.selected = NativeApplication.nativeApplication.startAtLogin
    return true
  } else {
    return false
  }
}

private function saveConfigs(cw:ConfigWindow):void {
  FMR.saveRssUrl(cw.rssUrl.text)
  if (FMR.saveUpdateInterval(cw.updateInterval.value)) {
    FMR.updateTimer.delay = cw.updateInterval.value * 1000
  }
  FMR.saveDisplayTime(cw.displayTime.value)
  NativeApplication.nativeApplication.startAtLogin = cw.autoStart.selected
}

private function clearData(cw:ConfigWindow):void {
  try {
    FMR.initializeDb()
    loadConfigs(cw)
    cw.stage.focus = cw.rssUrl
  } catch (error:SQLError) {
    trace('error.message:', error.message)
    trace('error.details:', error.details)
  }

  cw.initializeData.enabled = false
  cw.doInitializeData.selected = false
}
