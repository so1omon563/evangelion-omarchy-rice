import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
  id:root
  property string locale:"en-US"
  property string direction:"ltr"
  property var strings:({})
  readonly property bool rtl:direction==="rtl"
  function refresh(){ if(!probe.running) probe.running=true }
  function accept(text){ try { var value=JSON.parse(String(text)); locale=String(value.locale||"en-US"); direction=String(value.direction||"ltr"); strings=value.strings||({}) } catch(error){} }
  function tr(key,args){
    var value=String(strings[key]===undefined?key:strings[key]), fields=args||({})
    for(var name in fields) value=value.split("{"+name+"}").join(String(fields[name]))
    return value
  }
  Component.onCompleted:refresh()
  property FileView stateView:FileView { path:Quickshell.env("HOME")+"/.local/state/evangelion-rice/i18n/state.json"; watchChanges:true; printErrors:false; onFileChanged:root.refresh() }
  property Process probe:Process { command:["magi-i18n","catalog"]; stdout:StdioCollector { onStreamFinished:root.accept(text) } }
}
