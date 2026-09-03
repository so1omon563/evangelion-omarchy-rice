import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../evangelion.motion" as Motion
import "../evangelion.localization" as Localization

Item {
  id:root
  property bool opened:false
  property var workspaces:[]
  property int selected:0
  property string notice:""
  readonly property var current:workspaces.length?workspaces[Math.max(0,Math.min(selected,workspaces.length-1))]:null
  readonly property var targetScreen:(Quickshell.screens||[]).length?Quickshell.screens[0]:null
  Motion.MotionState{id:motion} Localization.I18n{id:i18n}
  function refresh(){ if(!probe.running)probe.running=true }
  function loadFields(){ if(!current)return; nameInput.text=current.name||""; shortInput.text=current.short||""; channelInput.text=current.channel||"" }
  function choose(delta){ if(!workspaces.length)return; selected=(selected+delta+workspaces.length)%workspaces.length;loadFields();keyCatcher.forceActiveFocus() }
  function show(){opened=true;notice="";refresh();keyCatcher.forceActiveFocus()}
  function hide(){opened=false}
  function save(){if(!current||writer.running)return;writer.command=["magi-workspaces","set",String(current.id),nameInput.text,"--short",shortInput.text,"--channel",channelInput.text];writer.running=true}
  Process{id:probe;command:["magi-workspaces","status","--json","--width","1366"];stdout:StdioCollector{onStreamFinished:{try{root.workspaces=JSON.parse(String(text)).workspaces||[];root.loadFields()}catch(error){root.notice=i18n.tr("workspaces.error")}}}}
  Process{id:writer;stdout:StdioCollector{onStreamFinished:{try{JSON.parse(String(text));root.notice=i18n.tr("workspaces.saved");root.refresh()}catch(error){root.notice=i18n.tr("workspaces.error")}}}}
  IpcHandler{target:"workspace-names"
    function toggle():string{root.opened?root.hide():root.show();return root.opened?"open":"closed"}
    function open():string{root.show();return"open"}
    function close():string{root.hide();return"closed"}
    function reload():string{root.refresh();return"reloading"}
  }
  PanelWindow{
    screen:root.targetScreen;visible:root.opened;color:"transparent";anchors{top:true;left:true;right:true;bottom:true}
    WlrLayershell.namespace:"magi-workspace-names";WlrLayershell.layer:WlrLayer.Overlay;WlrLayershell.keyboardFocus:WlrKeyboardFocus.Exclusive;exclusionMode:ExclusionMode.Ignore
    Rectangle{anchors.fill:parent;color:"#d9070610"} MouseArea{anchors.fill:parent;onClicked:root.hide()}
    Rectangle{
      width:Math.min(parent.width-80,920);height:Math.min(parent.height-80,610);anchors.centerIn:parent;color:"#f20a0810";border.width:2;border.color:"#62d8ff";radius:4
      opacity:motion.off||root.opened?1:0;Behavior on opacity{enabled:!motion.off;NumberAnimation{duration:motion.standardMs;easing.type:Easing.OutCubic}}
      MouseArea{anchors.fill:parent;onClicked:{}}
      Item{id:keyCatcher;anchors.fill:parent;focus:true;Accessible.role:Accessible.Dialog;Accessible.name:i18n.tr("workspaces.title")+(root.current?". Workspace "+root.current.id+", "+nameInput.text:"");Accessible.description:i18n.tr("workspaces.keys");Keys.priority:Keys.BeforeItem
        Keys.onPressed:function(event){
          if(event.key===Qt.Key_Escape)root.hide()
          else if(event.key===Qt.Key_Up&&!(event.modifiers&Qt.ControlModifier))root.choose(-1)
          else if(event.key===Qt.Key_Down&&!(event.modifiers&Qt.ControlModifier))root.choose(1)
          else if(event.key===Qt.Key_S&&(event.modifiers&Qt.ControlModifier))root.save()
          else if(event.key===Qt.Key_R&&(event.modifiers&Qt.ControlModifier))root.refresh()
          else return
          event.accepted=true
        }
        Column{anchors.fill:parent;anchors.margins:28;spacing:16
          Row{width:parent.width;height:50
            Column{width:parent.width*.75;spacing:4
              Text{text:i18n.tr("workspaces.title").toUpperCase();color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:21;font.bold:true;font.letterSpacing:2}
              Text{text:i18n.tr("workspaces.subtitle").toUpperCase();color:"#a89eb0";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.letterSpacing:1}
            }
            Text{width:parent.width*.25;horizontalAlignment:Text.AlignRight;text:"IDENTITY // "+String(root.current?root.current.id:0).padStart(2,"0");color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;font.bold:true}
          }
          Rectangle{width:parent.width;height:1;color:"#46354f"}
          Row{width:parent.width;height:parent.height-135;spacing:18
            Column{width:210;spacing:6
              Repeater{model:root.workspaces;delegate:Rectangle{required property var modelData;required property int index;width:parent.width;height:54;color:index===root.selected?"#3262d8ff":"#8a100d16";border.width:index===root.selected?1:0;border.color:"#62d8ff"
                Column{anchors.fill:parent;anchors.margins:9;spacing:3
                  Text{text:String(modelData.id).padStart(2,"0")+" // "+String(modelData.resolved_short);color:index===root.selected?"#fff6dc":"#b8adbf";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}
                  Text{width:parent.width;elide:Text.ElideRight;text:String(modelData.name);color:"#8E809A";font.family:"JetBrainsMono Nerd Font";font.pixelSize:8}
                }
                MouseArea{anchors.fill:parent;onClicked:{root.selected=index;root.loadFields();keyCatcher.forceActiveFocus()}}
              }}
            }
            Rectangle{width:parent.width-228;height:parent.height;color:"#b308070d";border.width:1;border.color:"#7450a6"
              Column{anchors.fill:parent;anchors.margins:22;spacing:12
                Text{text:i18n.tr("workspaces.full_name").toUpperCase();color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.bold:true}
                Rectangle{width:parent.width;height:48;color:"#70181320";border.width:nameInput.activeFocus?2:1;border.color:nameInput.activeFocus?"#62d8ff":"#46354f"
                  TextInput{id:nameInput;anchors.fill:parent;anchors.margins:12;color:"#fff6dc";selectionColor:"#7450a6";font.family:"JetBrainsMono Nerd Font";font.pixelSize:13;maximumLength:48;activeFocusOnTab:true;Accessible.role:Accessible.EditableText;Accessible.name:i18n.tr("workspaces.full_name");Accessible.description:"Full workspace name, maximum 48 characters";verticalAlignment:TextInput.AlignVCenter}}
                Text{text:i18n.tr("workspaces.short").toUpperCase();color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.bold:true}
                Rectangle{width:parent.width;height:48;color:"#70181320";border.width:shortInput.activeFocus?2:1;border.color:shortInput.activeFocus?"#62d8ff":"#46354f"
                  TextInput{id:shortInput;anchors.fill:parent;anchors.margins:12;color:"#62d8ff";selectionColor:"#7450a6";font.capitalization:Font.AllUppercase;font.family:"JetBrainsMono Nerd Font";font.pixelSize:13;maximumLength:8;activeFocusOnTab:true;Accessible.role:Accessible.EditableText;Accessible.name:i18n.tr("workspaces.short");Accessible.description:"Compact workspace label, maximum 8 characters";verticalAlignment:TextInput.AlignVCenter}}
                Text{text:i18n.tr("workspaces.channel").toUpperCase();color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9;font.bold:true}
                Rectangle{width:parent.width;height:48;color:"#70181320";border.width:channelInput.activeFocus?2:1;border.color:channelInput.activeFocus?"#62d8ff":"#46354f"
                  TextInput{id:channelInput;anchors.fill:parent;anchors.margins:12;color:"#fff6dc";selectionColor:"#7450a6";font.family:"JetBrainsMono Nerd Font";font.pixelSize:12;maximumLength:64;activeFocusOnTab:true;Accessible.role:Accessible.EditableText;Accessible.name:i18n.tr("workspaces.channel");Accessible.description:"Workspace channel description, maximum 64 characters";verticalAlignment:TextInput.AlignVCenter}}
                Rectangle{width:parent.width;height:74;color:"#50100d16";border.width:1;border.color:"#6e5720"
                  Column{anchors.fill:parent;anchors.margins:11;spacing:7
                    Text{text:i18n.tr("workspaces.preview").toUpperCase();color:"#8f8299";font.family:"JetBrainsMono Nerd Font";font.pixelSize:8}
                    Row{spacing:18
                      Text{text:"2560  "+(root.current?(String(root.current.id).padStart(2,"0")+"·"+nameInput.text.split("·").pop().trim().slice(0,12)):"—");color:"#f6d447";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}
                      Text{text:"1366  "+(root.current?(String(root.current.id).padStart(2,"0")+"·"+shortInput.text.toUpperCase()):"—");color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}
                      Text{text:"<1200  "+(root.current?String(root.current.id):"—");color:"#a89eb0";font.family:"JetBrainsMono Nerd Font";font.pixelSize:11;font.bold:true}
                    }
                  }
                }
                Text{width:parent.width;text:root.notice;color:"#62d8ff";font.family:"JetBrainsMono Nerd Font";font.pixelSize:10;font.bold:true}
              }
            }
          }
          Text{width:parent.width;horizontalAlignment:Text.AlignHCenter;text:i18n.tr("workspaces.keys").toUpperCase();color:"#8f8299";font.family:"JetBrainsMono Nerd Font";font.pixelSize:9}
        }
      }
    }
  }
}
