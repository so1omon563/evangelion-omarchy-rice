import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import "../evangelion.motion" as Motion

Item {
  id: root
  property bool opened: false
  property var entries: []
  property int selected: 0
  property string category: ""
  property string notice: "LOCAL ARCHIVE · OFFLINE READY"
  property string clearToken: ""
  readonly property var active: entries.length ? entries[Math.max(0,Math.min(selected,entries.length-1))] : null
  readonly property var targetScreen: (Quickshell.screens||[]).length ? Quickshell.screens[0] : null
  Motion.MotionState { id: motion }
  function show(){opened=true;selected=0;clearToken="";query.text="";refresh();query.forceActiveFocus()}
  function hide(){opened=false;clearToken=""}
  function refresh(){if(!searchProc.running){searchProc.command=["magi-operations-log","search",query.text,"--limit","50"];if(category)searchProc.command.push("--category",category);searchProc.running=true}}
  function accept(raw){try{var value=JSON.parse(String(raw));entries=value.entries||[];selected=Math.min(selected,Math.max(0,entries.length-1));notice=String(value.count||0).padStart(2,"0")+" RECORDS · "+String(value.storage_bytes||0)+" BYTES · LOCAL ONLY"}catch(e){entries=[];notice="ARCHIVE UNAVAILABLE"}}
  function move(n){if(entries.length){selected=(selected+n+entries.length)%entries.length;list.positionViewAtIndex(selected,ListView.Contain)}}
  function invoke(){if(active&&active.action){invokeProc.command=["magi-operations-log","invoke",active.id];invokeProc.running=true}else notice="NO SAFE ACTION REGISTERED"}
  function requestClear(){if(clearToken){clearProc.command=["magi-operations-log","clear","--confirm",clearToken];clearProc.running=true}else{clearPlanProc.command=["magi-operations-log","clear-plan"];clearPlanProc.running=true}}
  Timer{id:debounce;interval:100;onTriggered:root.refresh()}
  Process{id:searchProc;stdout:StdioCollector{onStreamFinished:root.accept(text)}}
  Process{id:invokeProc;stdout:StdioCollector{onStreamFinished:{root.notice="ACTION DISPATCHED"}}}
  Process{id:exportProc;stdout:StdioCollector{onStreamFinished:{try{root.notice="EXPORTED // "+JSON.parse(String(text)).path}catch(e){root.notice="EXPORT FAILED"}}}}
  Process{id:clearPlanProc;stdout:StdioCollector{onStreamFinished:{try{var v=JSON.parse(String(text));root.clearToken=v.token;root.notice="CONFIRM CLEAR OF "+v.entries+" RECORDS // PRESS C AGAIN"}catch(e){root.notice="CLEAR PREPARATION FAILED"}}}}
  Process{id:clearProc;stdout:StdioCollector{onStreamFinished:{root.clearToken="";root.notice="ARCHIVE CLEARED";root.refresh()}}}
  IpcHandler{target:"magi-operations-log";function toggle():string{root.opened?root.hide():root.show();return root.opened?"open":"closed"}function open():string{root.show();return"open"}function close():string{root.hide();return"closed"}}
  PanelWindow {
    visible:root.opened;screen:root.targetScreen;color:"transparent";anchors{top:true;bottom:true;left:true;right:true}
    WlrLayershell.namespace:"magi-operations-log";WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive;exclusionMode:ExclusionMode.Ignore
    Rectangle{anchors.fill:parent;color:"#d8060509"} MouseArea{anchors.fill:parent;onClicked:root.hide()}
    Rectangle {
      width:Math.min(parent.width-48,860);height:Math.min(parent.height-72,700);anchors.centerIn:parent;color:Color.popups.background;border.width:2;border.color:Color.accent;radius:4
      MouseArea{anchors.fill:parent;onClicked:query.forceActiveFocus()}
      ColumnLayout{anchors.fill:parent;anchors.margins:20;spacing:10
        RowLayout{Layout.fillWidth:true;Text{text:"MAGI // OPERATIONS LOG";color:Color.accent;font.family:"JetBrainsMono Nerd Font";font.pixelSize:18;font.bold:true;font.letterSpacing:2}Item{Layout.fillWidth:true}Text{text:"PRIVACY-SANITIZED";color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}}
        Rectangle{Layout.fillWidth:true;Layout.preferredHeight:46;color:Color.background;border.width:1;border.color:query.activeFocus?Color.accent:Color.muted
          TextInput{id:query;anchors.fill:parent;anchors.margins:12;color:Color.foreground;selectionColor:Color.selection;font.family:"JetBrainsMono Nerd Font";font.pixelSize:13;clip:true;Accessible.role:Accessible.EditableText;Accessible.name:"Search notification and MAGI event history";Accessible.description:"Type to search, arrows navigate, Enter invokes a safe action, C clears with confirmation, E exports, Escape closes";onTextChanged:{root.selected=0;debounce.restart()}
            Keys.priority:Keys.BeforeItem;Keys.onPressed:function(event){if(event.key===Qt.Key_Escape)root.hide();else if(event.key===Qt.Key_Down)root.move(1);else if(event.key===Qt.Key_Up)root.move(-1);else if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter)root.invoke();else if(event.key===Qt.Key_C&&query.text.length===0)root.requestClear();else if(event.key===Qt.Key_E&&query.text.length===0){exportProc.command=["magi-operations-log","export"];exportProc.running=true}else return;event.accepted=true}}
        }
        ListView{id:list;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;spacing:5;model:root.entries;currentIndex:root.selected
          delegate:Rectangle{required property var modelData;required property int index;width:list.width;height:74;color:index===root.selected?Color.selection:Color.background;border.width:index===root.selected?1:0;border.color:Color.accent
            RowLayout{anchors.fill:parent;anchors.margins:10;spacing:12
              ColumnLayout{Layout.preferredWidth:105;Text{text:String(modelData.category||"SYSTEM").toUpperCase();color:Color.accent;font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.bold:true}Text{text:new Date((modelData.last_at||0)*1000).toLocaleString();color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:7}Text{text:(modelData.count||1)>1?"×"+modelData.count:"";color:"#F6D447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}}
              ColumnLayout{Layout.fillWidth:true;Text{Layout.fillWidth:true;text:String(modelData.summary||"");elide:Text.ElideRight;color:Color.foreground;font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}Text{Layout.fillWidth:true;text:String(modelData.detail||"");elide:Text.ElideRight;color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}Text{Layout.fillWidth:true;text:String(modelData.source||"MAGI").toUpperCase();elide:Text.ElideRight;color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:7}}
              Text{Layout.preferredWidth:85;horizontalAlignment:Text.AlignRight;text:modelData.action?"ENTER // ACT":"ARCHIVE";color:modelData.action?"#62D8FF":Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:8;font.bold:true}
            }
            MouseArea{anchors.fill:parent;onClicked:{root.selected=index;root.invoke()}}
          }
          Text{anchors.centerIn:parent;visible:root.entries.length===0;text:"NO MATCHING OPERATIONS";color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:11}
        }
        Text{Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;text:root.notice;color:root.clearToken?"#FF5A36":Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:8;font.bold:root.clearToken!==""}
        Text{Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;text:"↑↓ NAVIGATE · ENTER ACTION · C CLEAR · E EXPORT · ESC CLOSE";color:Color.muted;font.family:"JetBrainsMono Nerd Font";font.pixelSize:8}
      }
    }
  }
}
