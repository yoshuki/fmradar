package classes {
  import flash.display.NativeWindow
  import flash.display.NativeWindowInitOptions
  import flash.display.NativeWindowSystemChrome
  import flash.display.NativeWindowType
  import flash.display.Sprite
  import flash.display.StageAlign
  import flash.display.StageScaleMode
  import flash.events.Event
  import flash.events.MouseEvent
  import flash.text.StyleSheet
  import flash.text.TextField
  import flash.text.TextFormat

  public class MessageWindow extends NativeWindow {
    private static const STOCK_WIDTH:uint = 230

    public var timeToLive:uint

    private var manager:DisplayManager

    public function MessageWindow(message:Array, manager:DisplayManager):void {
      this.manager = manager

      var options:NativeWindowInitOptions = new NativeWindowInitOptions()
      options.systemChrome = NativeWindowSystemChrome.NONE
      options.transparent = true
      options.type = NativeWindowType.LIGHTWEIGHT
      super(options)

      stage.align = StageAlign.TOP_LEFT
      stage.scaleMode = StageScaleMode.NO_SCALE

      manager.addEventListener(DisplayManager.LIFE_TICK, lifeTick, false, 0, true)
      width = MessageWindow.STOCK_WIDTH

      var header:Sprite = new Sprite()
      stage.addChild(header)

      var roomName:TextField = new TextField()
      header.addChild(roomName)
      var headerColor:uint
      var headerHighlightColor:uint
      if (message[0] === '') {
        headerColor = 0x999999
        roomName.setTextFormat(new TextFormat('_明朝', 14, 0xffffff))
        roomName.text = message[1]
      } else {
        headerColor = 0x009900
        headerHighlightColor = 0xff9900
        var rnStyle:StyleSheet = new StyleSheet()
        rnStyle.setStyle('a', {fontFamily: 'serif', fontSize: '14', color: '#ffffff'})
        roomName.styleSheet = rnStyle
        roomName.htmlText = '<a href="'+FMR.escapeHTML(message[0])+'">'+FMR.escapeHTML(message[1])+'</a>'
        roomName.addEventListener(MouseEvent.MOUSE_OVER, function (event:MouseEvent):void {
          with (header.graphics) {
            clear()
            beginFill(headerHighlightColor, 0.8)
            drawRoundRect(2, 2, width - 4, roomName.height, 8, 8)
            endFill()
          }
        })
        roomName.addEventListener(MouseEvent.MOUSE_OUT, function (event:MouseEvent):void {
          with (header.graphics) {
            clear()
            beginFill(headerColor, 0.8)
            drawRoundRect(2, 2, width - 4, roomName.height, 8, 8)
            endFill()
          }
        })
      }
      roomName.x = 5
      roomName.y = 5
      roomName.width = roomName.textWidth * 1.1
      roomName.height = roomName.textHeight * 1.4

      with (header.graphics) {
        beginFill(headerColor, 0.8)
        drawRoundRect(2, 2, width - 4, roomName.height, 8, 8)
        endFill()
      }

      var closeButton:Sprite = new Sprite()
      header.addChild(closeButton)
      closeButton.x = STOCK_WIDTH - 15
      closeButton.buttonMode = true
      closeButton.addEventListener(MouseEvent.CLICK, function (event:MouseEvent):void {
        close()
      })
      with (closeButton.graphics) {
        beginFill(0xefefef, 0.7)
          var radius:Number = roomName.height / 3
          var offset:uint = 2

          drawCircle(0, (roomName.height / 2) + offset, radius)

          lineStyle(2, 0x666666, 0.8)
          moveTo((radius / 2) * -1, radius + offset)
          lineTo((radius / 2), (radius * 2) + offset)
          moveTo((radius / 2), radius + offset)
          lineTo((radius / 2) * -1, (radius * 2) + offset)
        endFill()
      }

      var textDisplay:TextField = new TextField()
      stage.addChild(textDisplay)
      textDisplay.text = message[2]
      textDisplay.wordWrap = true
      textDisplay.setTextFormat(new TextFormat('_ゴシック', 12, 0))
      textDisplay.x = 5
      textDisplay.y = roomName.height + 5
      textDisplay.width = width - 10
      textDisplay.height = textDisplay.textHeight * 1.4

      height = roomName.height + textDisplay.height + 20

      alwaysInFront = true
      draw()
    }

    public function animateY(endY:int):void {
      var dY:Number
      var animate:Function = function (event:Event):void {
          dY = (endY - y) / 4
          y += dY
          if (y <= endY) {
            y = endY
            stage.removeEventListener(Event.ENTER_FRAME, animate)
          }
        }
      stage.addEventListener(Event.ENTER_FRAME, animate)
    }

    public override function close():void{
      manager.removeEventListener(DisplayManager.LIFE_TICK, lifeTick)
      super.close()

      FMR.numOpenedMessages -= 1
    }

    private function draw():void {
      var background:Sprite = new Sprite()
      with (background.graphics) {
        beginFill(0xffffff, 0.9)
        drawRoundRect(2, 2, width - 4, height - 4, 8, 8)
        endFill()
      }
      stage.addChildAt(background, 0)
    }

    private function lifeTick(event:Event):void {
      timeToLive--
      if(timeToLive < 1) {
        close()
      }
    }
  }
}
