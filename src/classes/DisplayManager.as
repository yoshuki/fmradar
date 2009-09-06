package classes {
  import flash.display.Screen
  import flash.events.Event
  import flash.events.EventDispatcher
  import flash.events.TimerEvent
  import flash.utils.Timer

  public class DisplayManager extends EventDispatcher {
    public static const LIFE_TICK:String = 'lifeTick'

    private const GUTTER:uint = 10

    private var currentScreen:Screen
    private var lifeTicks:uint = 0
    private var lifeTimer:Timer = new Timer(1000)

    public function DisplayManager() {
      lifeTimer.addEventListener(TimerEvent.TIMER, function (event:Event):void {
        lifeTicks++
        var tickEvent:Event = new Event(LIFE_TICK)
        dispatchEvent(tickEvent)
      })
      lifeTimer.start()
    }

    public function displayMessage(message:Array, timeToLive:uint=10):void {
      FMR.numOpenedMessages += 1

      var screen:Screen = Screen.mainScreen
      var messageWindow:MessageWindow = new MessageWindow(message, this)
      var endY:int = screen.visibleBounds.bottom - (messageWindow.height * FMR.numOpenedMessages)

      messageWindow.timeToLive = timeToLive
      messageWindow.x = screen.visibleBounds.right - messageWindow.width
      messageWindow.y = screen.visibleBounds.bottom

      messageWindow.visible = true
      messageWindow.animateY(endY)
    }
  }
}
