import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons

BarWidget {
  id:root; moduleName:"evangelion.world-clock"; property bool popupOpen:false
  property var status:({utc:"--:--",zones:[],uptime_display:"--",met:({running:false,elapsed:0,display:"00:00:00"})})
  function refresh(){if(!probe.running)probe.running=true} function togglePopup(){popupOpen=!popupOpen;if(popupOpen)refresh()} function close(){popupOpen=false}
  function action(name){root.bar.run("magi-clock "+name);actionRefresh.restart()}
  implicitWidth:row.implicitWidth+Style.space(10); implicitHeight:barSize
  Process{id:probe;running:true;command:["magi-clock","status","--json"];stdout:SplitParser{onRead:function(line){try{root.status=JSON.parse(String(line))}catch(e){}}}}
  Timer{interval:1000;running:root.status.met.running||root.popupOpen;repeat:true;onTriggered:root.refresh()}
  Timer{interval:30000;running:!root.status.met.running&&!root.popupOpen;repeat:true;onTriggered:root.refresh()}
  Timer{id:actionRefresh;interval:300;repeat:false;onTriggered:root.refresh()}
  IpcHandler{target:"magi-clock";function toggle():string{root.togglePopup();return root.popupOpen?"open":"closed"}function open():string{root.popupOpen=true;root.refresh();return"open"}function close():string{root.close();return"closed"}function refresh():string{root.refresh();return"ok"}}
  Row{id:row;anchors.centerIn:parent;spacing:Style.space(5);Text{text:"󰥔";color:root.status.met.running?Color.accent:root.bar.barForeground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.body}Text{text:"UTC // "+root.status.utc;visible:!root.bar.vertical&&root.bar.width>=1600;color:root.bar.barForeground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true}}
  MouseArea{anchors.fill:parent;acceptedButtons:Qt.LeftButton|Qt.MiddleButton;cursorShape:Qt.PointingHandCursor;onClicked:function(mouse){if(mouse.button===Qt.MiddleButton)root.action("toggle");else root.togglePopup()}}
  PopupCard{anchorItem:root;bar:root.bar;owner:root;open:root.popupOpen;contentWidth:fittedContentWidth(Style.space(390));contentHeight:fittedContentHeight(panel.implicitHeight)
    Column{id:panel;anchors.fill:parent;spacing:Style.space(8)
      Text{text:"MAGI // WORLD CHRONOMETER";color:Color.accent;font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true;font.letterSpacing:1}
      Text{text:"TIME COORDINATION MATRIX";color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.heading;font.bold:true}
      Rectangle{width:parent.width;height:1;color:Color.accent;opacity:.5}
      Repeater{model:root.status.zones;delegate:Row{required property var modelData;width:panel.width
        Text{width:Style.space(105);text:modelData.label;color:modelData.label==="ARIZONA"?Color.accent:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.body;font.bold:true}
        Text{width:Style.space(58);text:modelData.time;color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.body;font.bold:true}
        Text{width:Style.space(92);text:modelData.date;color:Qt.darker(root.bar.foreground,1.25);font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption}
        Text{width:parent.width-Style.space(255);horizontalAlignment:Text.AlignRight;text:modelData.boundary;color:modelData.boundary==="TODAY"?Qt.darker(root.bar.foreground,1.45):"#F6D447";font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true}
      }}
      Rectangle{width:parent.width;height:1;color:Color.muted;opacity:.4}
      Text{text:"SESSION UPTIME // "+root.status.uptime_display;color:Qt.darker(root.bar.foreground,1.2);font.family:root.bar.fontFamily;font.pixelSize:Style.font.body;font.bold:true}
      Text{text:"MISSION ELAPSED // "+root.status.met.display;color:root.status.met.running?Color.accent:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.heading;font.bold:true}
      Row{width:parent.width;spacing:Style.space(8);Repeater{model:[{label:root.status.met.running?"PAUSE":"START",action:"toggle"},{label:"RESET",action:"reset"}];delegate:BorderSurface{required property var modelData;width:(panel.width-Style.space(8))/2;height:Style.space(36);color:Style.normalFillFor(root.bar.foreground,Color.accent);borderSpec:Border.controlSpec("normal",root.bar.foreground,Color.accent);Text{anchors.centerIn:parent;text:modelData.label;color:root.bar.foreground;font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption;font.bold:true}MouseArea{anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:root.action(modelData.action)}}}
      }
      Text{text:"MIDDLE CLICK // START OR PAUSE MET";color:Qt.darker(root.bar.foreground,1.5);font.family:root.bar.fontFamily;font.pixelSize:Style.font.caption}
    }
  }
}
