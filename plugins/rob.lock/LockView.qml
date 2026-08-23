import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property string userName: ""
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property bool showPassword: false
  property date now: new Date()

  readonly property bool errorState: failureMessage.length > 0
  readonly property int panelWidth: Math.round(Math.max(420, Math.min(560, width * 0.34)))
  readonly property int margin: 56
  readonly property int fieldWidth: panelWidth - margin * 2

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function alpha(c, a) {
    return Util.alpha(c, a)
  }

  function greeting() {
    var h = root.now.getHours()
    if (h < 12) return "Good morning"
    if (h < 17) return "Good afternoon"
    return "Good evening"
  }

  function displayName() {
    var u = String(root.userName || "")
    return u ? u.charAt(0).toUpperCase() + u.slice(1) : ""
  }

  function forcePasswordFocus() {
    input.forceActiveFocus()
  }

  function syncPasswordText() {
    if (input.text === passwordText) return
    syncingPasswordText = true
    input.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }
  onFailureMessageChanged: {
    if (errorState) shake.restart()
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.now = new Date()
  }

  Rectangle {
    anchors.fill: parent
    color: Color.background
  }

  Image {
    id: background
    anchors.fill: parent
    source: root.loadBackground ? root.fileUrl(root.backgroundPath) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    sourceSize.width: width
    sourceSize.height: height
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
    onPositionChanged: root.wakeRequested()
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
      blurEnabled: root.loadBackground && background.status === Image.Ready
      blur: 1.0
      blurMax: 32
    }

    Rectangle {
      anchors.fill: parent
      color: root.alpha(Color.background, 0.55)
    }

    Rectangle {
      anchors.left: parent.left
      width: 1
      height: parent.height
      color: root.alpha(Color.lock.text, 0.14)
    }

    Column {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: root.margin
      anchors.rightMargin: root.margin
      spacing: 22

      Item {
        id: avatar
        anchors.horizontalCenter: parent.horizontalCenter
        width: 84
        height: 84

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: Color.lock.text
        }

        Text {
          anchors.centerIn: parent
          visible: avatarImg.status !== Image.Ready
          text: root.displayName().length > 0 ? root.displayName().charAt(0) : ""
          color: Color.background
          font.family: Style.font.family
          font.pixelSize: 30
          font.weight: Font.Bold
        }

        Rectangle {
          id: avatarClip
          anchors.fill: parent
          radius: width / 2
          clip: true
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

        Rectangle {
          anchors.fill: parent
          radius: width / 2
          color: "transparent"
          border.width: 3
          border.color: root.alpha(Color.lock.text, 0.25)
        }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.greeting()
          color: root.alpha(Color.lock.text, 0.7)
          font.family: Style.font.family
          font.pixelSize: 14
          font.letterSpacing: 2
        }
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.displayName()
          color: Color.lock.text
          font.family: Style.font.family
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
        color: root.alpha(Color.background, 0.75)
        border.width: 2
        border.color: root.errorState
          ? Color.lock.borderError
          : (input.activeFocus ? Color.lock.borderActive : root.alpha(Color.lock.text, 0.45))
        clip: true

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

        Text {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 44
          text: root.authenticatingPassword ? "Checking…"
              : (root.errorState ? "Incorrect password" : "Password")
          visible: input.text.length === 0
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
          color: root.errorState ? Color.lock.textError : root.alpha(Color.lock.placeholder, 0.9)
          font.family: Style.font.family
          font.pixelSize: 16
        }

        TextInput {
          id: input
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 44
          verticalAlignment: TextInput.AlignVCenter
          activeFocusOnPress: true
          clip: true
          enabled: root.inputEnabled && !root.authenticatingPassword
          readOnly: root.authenticatingPassword
          echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
          passwordCharacter: "\u25CF"
          passwordMaskDelay: 0
          color: Color.lock.text
          selectionColor: Color.lock.selection
          selectedTextColor: Color.lock.text
          font.family: Style.font.family
          font.pixelSize: 16
          cursorVisible: activeFocus && input.text.length > 0 && !root.authenticatingPassword
          cursorDelegate: Rectangle {
            width: 2
            color: Color.lock.text
            visible: input.cursorVisible
          }
          focus: true

          onTextChanged: {
            if (!root.syncingPasswordText) root.passwordTextEdited(text)
            if (text.length > 0) root.wakeRequested()
            if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
          }

          onAccepted: {
            var submitted = text
            root.passwordTextEdited("")
            if (submitted.length > 0) root.submitPassword(submitted)
          }

          Keys.onPressed: function(event) {
            root.wakeRequested()
            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
              root.showPassword = !root.showPassword
              event.accepted = true
            } else if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              root.passwordTextEdited("")
              event.accepted = true
            }
          }
        }

        Text {
          id: fingerprintIcon
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          visible: root.fingerprintConfigured
          text: "󰈷"
          color: Color.lock.placeholder
          font.family: Style.font.family
          font.pixelSize: 18
        }

        Text {
          id: eye
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          visible: !root.fingerprintConfigured
          text: root.showPassword ? "󰈉" : "󰈈"
          color: root.showPassword ? Color.lock.text : root.alpha(Color.lock.placeholder, 0.9)
          font.family: Style.font.family
          font.pixelSize: 18
        }
        MouseArea {
          anchors.fill: eye
          cursorShape: Qt.PointingHandCursor
          onClicked: { root.showPassword = !root.showPassword; input.forceActiveFocus() }
        }
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.errorState ? "Incorrect password, try again" : "Press Enter to sign in"
        color: root.errorState ? Color.lock.textError : root.alpha(Color.lock.text, 0.55)
        font.family: Style.font.family
        font.pixelSize: 11
        font.letterSpacing: 1
      }
    }

    Text {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.margins: root.margin
      text: "󰌾  Sign in"
      color: root.alpha(Color.lock.text, 0.45)
      font.family: Style.font.family
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
      color: Color.lock.text
      font.family: Style.font.family
      font.pixelSize: 96
      font.weight: Font.DemiBold
      font.letterSpacing: -2
    }
    Text {
      text: Qt.formatDate(root.now, "dddd, d MMMM")
      color: root.alpha(Color.lock.text, 0.85)
      font.family: Style.font.family
      font.pixelSize: 24
    }
  }
}
