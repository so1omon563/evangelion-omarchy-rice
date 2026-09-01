import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id:root
  I18n { id:i18n }
  Process { id:setter; onExited:i18n.refresh() }
  IpcHandler { target:"magi-i18n"
    function setLocale(locale:string):string { setter.command=["magi-i18n","set",locale]; setter.running=true; return "queued" }
    function reset():string { setter.command=["magi-i18n","reset"]; setter.running=true; return "queued" }
    function state():string { return JSON.stringify({locale:i18n.locale,direction:i18n.direction}) }
  }
}
