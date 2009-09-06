/*
 * URLLoader
 */
private function ioErrorHandler(event:IOErrorEvent):void {
  trace('ioErrorHandler:')
  trace(event)
}

private function securityErrorHandler(event:SecurityErrorEvent):void {
  trace('securityErrorHandler:')
  trace(event)
}
