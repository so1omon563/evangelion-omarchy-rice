import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion
import "../evangelion.localization" as Localization

Item {
  id:root
  property bool opened:false
  property var scenes:[]
  property int selected:0
  property var pending:null
  property string authority:"auto"
  property bool audioAuthorized:false
  property string notice:""
  readonly property var active:scenes.length?scenes[Math.max(0,Math.min(selected,scenes.length-1))]:null
  readonly property var targetScreen:(Quickshell.screens||[]).length?Quickshell.screens[0]:null
  Motion.MotionState{id:motion}
  Localization.I18n{id:i18n}
  function refresh(){if(!statusProc.running)statusProc.running=true}
  function show(){opened=true;pending=null;notice="";refresh();keys.forceActiveFocus()}
  function hide(){opened=false;pending=null}
  function move(amount){if(!scenes.length)return;selected=(selected+amount+scenes.length)%scenes.length;pending=null}
  function preview(){if(!active||previewProc.running)return;previewProc.command=["magi-scene","preview",active.id];previewProc.running=true}
  function applyPending(){if(!pending||applyProc.running)return;applyProc.command=["magi-scene","apply",pending.scene.id,"--confirm",pending.plan_id];applyProc.running=true}
  function acceptStatus(text){try{var value=JSON.parse(String(text));scenes=value.scenes||[];authority=value.authority||"auto";audioAuthorized=!!value.audio_authorized}catch(error){notice=i18n.tr("scenes.error")}}
  Process{id:statusProc;command:["magi-scene","status"];stdout:StdioCollector{onStreamFinished:root.acceptStatus(text)}}
  Process{id:previewProc;stdout:StdioCollector{onStreamFinished:{try{root.pending=JSON.parse(String(text));root.notice=""}catch(error){root.notice=i18n.tr("scenes.error")}}}}
  Process{id:applyProc;stdout:StdioCollector{onStreamFinished:{try{JSON.parse(String(text));root.pending=null;root.notice=i18n.tr("scenes.applied");root.refresh()}catch(error){root.notice=i18n.tr("scenes.error")}}}}
  Process{id:undoProc;command:["magi-scene","undo"];stdout:StdioCollector{onStreamFinished:{root.pending=null;root.notice=i18n.tr("scenes.undone");root.refresh()}}}
  Process{id:autoProc;command:["magi-scene","auto"];stdout:StdioCollector{onStreamFinished:{root.pending=null;root.notice=i18n.tr("scenes.auto");root.refresh()}}}
  IpcHandler{target:"scene-editor";function toggle():string{root.opened?root.hide():root.show();return root.opened?"open":"closed"}function open():string{root.show();return"open"}function close():string{root.hide();return"closed"}function refresh():string{root.refresh();return"ok"}}
  PanelWindow{
    screen:root.targetScreen;visible:root.opened;color:"transparent";anchors{top:true;left:true;right:true;bottom:true}
    WlrLayershell.namespace:"magi-scene-editor";WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive;exclusionMode:ExclusionMode.Ignore
    Rectangle{anchors.fill:parent;color:"#dc060510"}
    MouseArea{anchors.fill:parent;onClicked:root.hide()}
    Rectangle{
      width:Math.min(parent.width-80,1120);height:Math.min(parent.height-80,700);anchors.centerIn:parent;color:"#f20a0810";border.width:2;border.color:"#9cf23a";radius:4
      opacity:motion.off||root.opened?1:0;Behavior on opacity{enabled:!motion.off;NumberAnimation{duration:motion.standardMs;easing.type:Easing.OutCubic}}
      MouseArea{anchors.fill:parent;onClicked:{}}
      Item{id:keys;anchors.fill:parent;focus:true;Accessible.role:Accessible.Dialog;Accessible.name:i18n.tr("scenes.title")+(root.active?". Selected "+root.active.label:"");Accessible.description:i18n.tr("scenes.keys");Keys.priority:Keys.BeforeItem;Keys.onPressed:function(event){
        if(event.key===Qt.Key_Escape)root.hide();else if(event.key===Qt.Key_Up||event.key===Qt.Key_K)root.move(-1);else if(event.key===Qt.Key_Down||event.key===Qt.Key_J)root.move(1);else if(event.key===Qt.Key_Return||event.key===Qt.Key_Enter||event.key===Qt.Key_Space)root.preview();else if(event.key===Qt.Key_A&&root.pending)root.applyPending();else if(event.key===Qt.Key_U&&!undoProc.running)undoProc.running=true;else if(event.key===Qt.Key_T&&!autoProc.running)autoProc.running=true;else if(event.key===Qt.Key_R)root.refresh();else return;event.accepted=true}}
      Column{anchors.fill:parent;anchors.margins:28;spacing:16
        Row{width:parent.width;height:54
          Column{width:parent.width*.72;spacing:4;Text{text:i18n.tr("scenes.title").toUpperCase();color:"#9cf23a";font.family:"JetBrainsMono Nerd Font";font.pixelSize:22;font.bold:true;font.letterSpacing:2}Text{text:i18n.tr("scenes.subtitle").toUpperCase();color:"#a89eb0";font.family:"JetBrainsMono Nerd Font";font.pixelSize:10;font.letterSpacing:1}}
          Column{width:parent.width*.28;spacing:4;Text{width:parent.width;horizontalAlignment:Text.AlignRight;text:"AUTHORITY // "+root.authority.toUpperCase();color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;font.bold:true}Text{width:parent.width;horizontalAlignment:Text.AlignRight;text:root.audioAuthorized?"AUDIO // AUTHORIZED":"AUDIO // INTERLOCKED";color:root.audioAuthorized?"#f6d447":"#8f8299";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}}
        }
        Rectangle{width:parent.width;height:1;color:"#3f6e2a"}
        Row{width:parent.width;height:parent.height-150;spacing:18
          Column{width:parent.width*.42;spacing:7
            Repeater{model:root.scenes;delegate:Rectangle{required property var modelData;required property int index;width:parent.width;height:66;color:index===root.selected?"#309cf23a":"#8a100d16";border.width:index===root.selected?1:0;border.color:"#9cf23a"
              Row{anchors.fill:parent;anchors.margins:12;spacing:10;Text{width:30;text:String(index+1).padStart(2,"0");color:index===root.selected?"#9cf23a":"#8f8299";font.family:"JetBrainsMono Nerd Font";font.pixelSize:10}Column{width:parent.width-42;spacing:3;Text{width:parent.width;elide:Text.ElideRight;text:String(modelData.label).toUpperCase();color:index===root.selected?"#fff6dc":"#c4bacb";font.family:"JetBrainsMono Nerd Font";font.pixelSize:13;font.bold:true}Text{text:String(modelData.affinity).toUpperCase()+" · "+String(modelData.terminal).toUpperCase();color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}}}
              MouseArea{anchors.fill:parent;onClicked:{root.selected=index;root.pending=null}}
            }}
          }
          Rectangle{width:parent.width*.58-18;height:parent.height;color:"#b308070d";border.width:1;border.color:"#7450a6"
            Column{anchors.fill:parent;anchors.margins:22;spacing:12
              Text{text:root.active?String(root.active.label).toUpperCase():"—";color:"#9cf23a";font.family:"JetBrainsMono Nerd Font";font.pixelSize:19;font.bold:true}
              Text{width:parent.width;wrapMode:Text.WordWrap;text:root.active?("WALLPAPER  "+root.active.wallpaper+"\nAFFINITY   "+root.active.affinity+"\nTERMINAL   "+root.active.terminal+"\nAMBIENT    "+root.active.ambient+"\nMOTION     "+root.active.motion+"\nSOUND      "+root.active.sound).toUpperCase():"";color:"#d8cedf";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;lineHeight:1.45}
              Rectangle{width:parent.width;height:1;color:"#46354f"}
              Text{text:i18n.tr("scenes.preview").toUpperCase();color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:10;font.bold:true}
              Repeater{model:root.pending?root.pending.actions:[];delegate:Text{required property var modelData;width:parent.width;elide:Text.ElideRight;text:(modelData.component+"  →  "+modelData.target+"  ["+modelData.status+"]").toUpperCase();color:modelData.status==="blocked"?"#f05a68":(modelData.status==="degraded"?"#f6d447":"#a89eb0");font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}}
              Text{width:parent.width;wrapMode:Text.WordWrap;text:root.notice;color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:10;font.bold:true}
            }
          }
        }
        Text{width:parent.width;horizontalAlignment:Text.AlignHCenter;text:i18n.tr("scenes.keys").toUpperCase();color:"#8f8299";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.letterSpacing:.5}
      }
    }
  }
}
