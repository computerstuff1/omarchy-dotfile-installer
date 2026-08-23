import QtQuick
import QtQuick.Effects

Rectangle {
  id: root
  width: 1920
  height: 1080
  color: "transparent"

  property string currentUser: userModel.lastUser
  property bool loginFailed: false
  property bool showPassword: false
  property date now: new Date()
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }

  readonly property int panelWidth: Math.round(Math.max(420, Math.min(560, width * 0.34)))
  readonly property int margin: 56
  readonly property int fieldWidth: panelWidth - margin * 2

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  function withAlpha(hex, alpha) {
    var h = String(hex).replace("#", "")
    if (h.length === 8) h = h.substring(0, 6)
    return Qt.rgba(
      parseInt(h.substring(0, 2), 16) / 255,
      parseInt(h.substring(2, 4), 16) / 255,
      parseInt(h.substring(4, 6), 16) / 255,
      alpha
    )
  }

  function greeting() {
    var h = root.now.getHours()
    if (h < 12) return "Good morning"
    if (h < 17) return "Good afternoon"
    return "Good evening"
  }

  function displayName() {
    var u = root.currentUser
    return u ? u.charAt(0).toUpperCase() + u.slice(1) : ""
  }

  function startLogin() {
    root.loginFailed = false
    sddm.login(root.currentUser, input.text, root.sessionIndex)
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.loginFailed = true
      input.text = ""
      input.focus = true
      shake.restart()
    }
    function onLoginSucceeded() { root.loginFailed = false }
  }

  Image {
    id: background
    anchors.fill: parent
    source: "wallpaper.png"
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
  }

  Item {
    id: panel
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.panelWidth
    clip: true

    MultiEffect {
      anchors.fill: parent
      source: ShaderEffectSource {
        sourceItem: background
        sourceRect: Qt.rect(panel.x, panel.y, panel.width, panel.height)
      }
      blurEnabled: true
      blur: 1.0
      blurMax: 32
    }
    Rectangle { anchors.fill: parent; color: root.withAlpha("#1a1b26", 0.55) }
    Rectangle { anchors.left: parent.left; width: 1; height: parent.height; color: root.withAlpha("#a9b1d6", 0.14) }

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: root.margin
      spacing: 22

      Item {
        id: avatar
        anchors.horizontalCenter: parent.horizontalCenter
        width: 84
        height: width

        Rectangle { anchors.fill: parent; radius: width / 2; color: "#a9b1d6" }

        Text {
          anchors.centerIn: parent
          visible: avatarImg.status !== Image.Ready
          text: "R"
          color: "#1a1b26"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 30
          font.weight: Font.Bold
        }

        Item {
          anchors.fill: parent
          visible: avatarImg.source.toString().length > 0
          layer.enabled: avatarImg.source.toString().length > 0
          layer.smooth: true
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: circleMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
          }

          Image {
            id: avatarImg
            anchors.fill: parent
            source: "avatar.png"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 168
            sourceSize.height: 168
          }
        }

        Item {
          id: circleMask
          anchors.fill: parent
          visible: false
          layer.enabled: true
          Rectangle { anchors.fill: parent; radius: width / 2; color: "white" }
        }

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: "transparent"
          border.width: 3
          border.color: root.withAlpha("#a9b1d6", 0.25)
        }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.greeting()
          color: root.withAlpha("#a9b1d6", 0.7)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 14
          font.letterSpacing: 2
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.displayName()
          color: "#a9b1d6"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 28
          font.weight: Font.DemiBold
        }
      }

      Rectangle {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fieldWidth
        height: 58
        radius: 12
        color: root.withAlpha("#1a1b26", 0.75)
        border.width: 2
        border.color: root.loginFailed ? "#f7768e" : (input.activeFocus ? root.withAlpha("#a9b1d6", 0.9) : root.withAlpha("#a9b1d6", 0.45))
        clip: true

        Text {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 44
          text: root.loginFailed ? "Incorrect password" : "Password"
          visible: input.text.length === 0
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          color: root.loginFailed ? "#f7768e" : root.withAlpha("#a9b1d6", 0.66)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
        }

        TextInput {
          id: input
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 44
          verticalAlignment: TextInput.AlignVCenter
          echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
          passwordCharacter: "●"
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 16
          font.letterSpacing: 4
          color: "#a9b1d6"
          selectionColor: root.withAlpha("#7aa2f7", 0.45)
          selectedTextColor: "#a9b1d6"
          cursorDelegate: Rectangle { width: 2; color: "#a9b1d6" }
          cursorVisible: activeFocus
          clip: true
          focus: true

          onTextChanged: root.loginFailed = false
          Keys.onReturnPressed: (event) => { root.startLogin(); event.accepted = true }
          Keys.onEnterPressed: (event) => { root.startLogin(); event.accepted = true }
          Keys.onPressed: (event) => {
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
              root.showPassword = !root.showPassword
              event.accepted = true
            }
          }
        }

        Text {
          id: eye
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          text: root.showPassword ? "󰈉" : "󰈈"
          color: root.showPassword ? "#a9b1d6" : root.withAlpha("#a9b1d6", 0.66)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 18
        }
        MouseArea {
          anchors.fill: eye
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.showPassword = !root.showPassword; input.forceActiveFocus() }
        }

        transform: Translate { id: shakeTranslate; x: 0 }
        SequentialAnimation {
          id: shake
          running: false
          NumberAnimation { target: shakeTranslate; property: "x"; from: 0; to: -8; duration: 40 }
          NumberAnimation { target: shakeTranslate; property: "x"; from: -8; to: 8; duration: 70 }
          NumberAnimation { target: shakeTranslate; property: "x"; from: 8; to: -6; duration: 60 }
          NumberAnimation { target: shakeTranslate; property: "x"; from: -6; to: 4; duration: 50 }
          NumberAnimation { target: shakeTranslate; property: "x"; from: 4; to: 0; duration: 40 }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.loginFailed ? "Incorrect password, try again" : "Press Enter to sign in"
        color: root.loginFailed ? "#f7768e" : root.withAlpha("#a9b1d6", 0.55)
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.letterSpacing: 1
      }
    }

    Text {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: root.margin
      text: "󰌾  Sign in"
      color: root.withAlpha("#a9b1d6", 0.45)
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 11
      font.letterSpacing: 2
    }
  }

  Column {
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 72
    anchors.bottomMargin: 64
    spacing: 4
    Text {
      text: Qt.formatTime(root.now, "h:mm:ssap")
      color: "#a9b1d6"
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 96
      font.weight: Font.DemiBold
      font.letterSpacing: -2
      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        shadowBlur: 1.0
        shadowVerticalOffset: 2
      }
    }
    Text {
      text: Qt.formatDate(root.now, "       dddd, d MMMM")
      color: root.withAlpha("#a9b1d6", 0.85)
      font.family: "JetBrainsMono Nerd Font"
      font.pixelSize: 24
      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.6)
        shadowBlur: 1.0
        shadowVerticalOffset: 1
      }
    }
  }

  Component.onCompleted: input.forceActiveFocus()
}