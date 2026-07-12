import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0
import "colors.js" as Colors

// Skyscrapers Layout
Rectangle {
    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }
    readonly property real s: Screen.height / 768
    id: root; width: Screen.width; height: Screen.height; color: "#14101a"
    
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property real ui: 0

    readonly property color roseUI: "#d05870"
    readonly property color peachSky: "#f0a060"
    readonly property color sunCream: "#fae8d0"
    readonly property color silhouettes: "#303c44"

    // Dynamic Accent Colors (6-Color Palette)
    property color accent1: roseUI
    property color accent2: roseUI
    property color accent3: roseUI
    property color accent4: roseUI
    property color accent5: roseUI
    property color accent6: roseUI

    // Returns white or dark text depending on accent brightness
    function contrastText(accentColor) {
        var r = accentColor.r;
        var g = accentColor.g;
        var b = accentColor.b;
        var luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        return luminance > 0.5 ? "#14101a" : "#fae8d0";
    }

    // Returns a readable accent color for dark backgrounds (ensuring minimum brightness)
    function readableAccent(accentColor) {
        var r = accentColor.r;
        var g = accentColor.g;
        var b = accentColor.b;
        var luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        if (luminance >= 0.4) {
            return accentColor;
        }
        var factor = 0.5;
        var target = root.sunCream;
        return Qt.rgba(r + (target.r - r) * factor, g + (target.g - g) * factor, b + (target.b - b) * factor, 1.0);
    }

    // Returns a readable accent color that dynamically lightens/darkens to contrast with the wallpaper
    function dynamicAccentForWallpaper(accentColor) {
        var r = accentColor.r;
        var g = accentColor.g;
        var b = accentColor.b;
        var luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        if (luminance > 0.5) {
            var factor = 0.6;
            var target = Qt.color("#14101a");
            return Qt.rgba(r + (target.r - r) * factor, g + (target.g - g) * factor, b + (target.b - b) * factor, 1.0);
        } else {
            return root.readableAccent(accentColor);
        }
    }

    function updateAccentColor(filePath) {
        console.log("updateAccentColor called with path: " + filePath);
        if (!filePath) {
            root.accent1 = root.roseUI;
            root.accent2 = root.roseUI;
            root.accent3 = root.roseUI;
            root.accent4 = root.roseUI;
            root.accent5 = root.roseUI;
            root.accent6 = root.roseUI;
            return;
        }
        var filename = filePath.substring(filePath.lastIndexOf('/') + 1);
        console.log("Checking cache for filename: " + filename);
        if (Colors && Colors.colorMap && Colors.colorMap[filename]) {
            var palette = Colors.colorMap[filename];
            if (palette && palette.length >= 6) {
                root.accent1 = palette[0];
                root.accent2 = palette[1];
                root.accent3 = palette[2];
                root.accent4 = palette[3];
                root.accent5 = palette[4];
                root.accent6 = palette[5];
                console.log("Accent colors updated from cache: " + filename + " -> " + palette.join(", "));
                return;
            }
        }
        var ext = filename.split('.').pop().toLowerCase();
        if (ext === "png" || ext === "jpg" || ext === "jpeg" || ext === "webp" || ext === "gif") {
            console.log("Extracting real-time color for image: " + filename);
            realtimeExtractor.imageSource = filePath;
        } else {
            root.accent1 = root.roseUI;
            root.accent2 = root.roseUI;
            root.accent3 = root.roseUI;
            root.accent4 = root.roseUI;
            root.accent5 = root.roseUI;
            root.accent6 = root.roseUI;
            console.log("Fallback accent color for video: " + filename);
        }
    }

    Canvas {
        id: realtimeExtractor
        width: 3
        height: 2
        visible: false
        property string imageSource: ""
        onImageSourceChanged: if (imageSource !== "") loadImage(imageSource)
        onImageLoaded: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, 3, 2);
            try {
                ctx.drawImage(imageSource, 0, 0, 3, 2);
                var pixel = ctx.getImageData(0, 0, 3, 2);
                function compToHex(c) {
                    var hex = c.toString(16);
                    return hex.length === 1 ? "0" + hex : hex;
                }
                function rgbAt(i) {
                    var off = i * 4;
                    return "#" + compToHex(pixel.data[off]) + compToHex(pixel.data[off+1]) + compToHex(pixel.data[off+2]);
                }
                // 6 pixels from 3x2 grid: top-left, top-center, top-right, bottom-left, bottom-center, bottom-right
                root.accent1 = rgbAt(0);
                root.accent2 = rgbAt(1);
                root.accent3 = rgbAt(2);
                root.accent4 = rgbAt(3);
                root.accent5 = rgbAt(4);
                root.accent6 = rgbAt(5);
                console.log("Real-time extracted 6-color palette: " + root.accent1 + ", " + root.accent2 + ", " + root.accent3 + ", " + root.accent4 + ", " + root.accent5 + ", " + root.accent6);
            } catch (e) {
                console.log("Failed to extract color in Canvas: " + e);
                root.accent1 = root.roseUI;
                root.accent2 = root.roseUI;
                root.accent3 = root.roseUI;
                root.accent4 = root.roseUI;
                root.accent5 = root.roseUI;
                root.accent6 = root.roseUI;
            }
        }
    }

    property string activeWallpaperPath: bgLoader.item ? bgLoader.item.selectedFile : ""
    onActiveWallpaperPathChanged: {
        root.updateAccentColor(activeWallpaperPath);
    }

    FontLoader { id: pf; source: "font/PixelifySans-Bold.ttf" }
    
    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || ""; property string uIcon: model.icon || "" } }

    // Auto-focus fix for Quickshell (Loader does not propagate focus: true)
    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Component.onCompleted: {
        fadeAnim.start();
        keyboard.numLock = true;
        initialColorTimer.start();
    }

    Timer {
        id: initialColorTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (bgLoader.item) {
                root.updateAccentColor(bgLoader.item.selectedFile);
            }
        }
    }

    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 2000; easing.type: Easing.OutSine }

    Loader { id: bgLoader; anchors.fill: parent; source: "BackgroundVideo.qml" }

    // View Overlays
    Rectangle { anchors.top: parent.top; width: parent.width; height: 160 * s; gradient: Gradient { GradientStop { position: 0.0; color: "#60000000" } GradientStop { position: 1.0; color: "transparent" } } }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 240 * s; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#90000000" } } }

    // HUD Section

    // Clock Unit
    Column {
        anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 60 * s
        spacing: 4 * s; opacity: root.ui
        
        Text {
            id: clk; text: Qt.formatTime(new Date(), "HH:mm")
            color: root.dynamicAccentForWallpaper(root.accent1); font.family: pf.name; font.pixelSize: 84 * s; font.letterSpacing: -2 * s
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text = Qt.formatTime(new Date(), "HH:mm") }
            layer.enabled: true; layer.effect: DropShadow { color: "#aa000000"; radius: 6; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
            color: root.dynamicAccentForWallpaper(root.accent2); font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    // Login Unit
    Column {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.margins: 60 * s
        width: 320 * s; spacing: 20 * s; opacity: root.ui

        // User Avatar
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 80 * s; height: 80 * s

            // Outer border ring
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: avatarMouse.containsMouse ? root.peachSky : root.readableAccent(root.accent2)
                border.width: 2 * s
                Behavior on border.color { ColorAnimation { duration: 150 } }
            }

            // Avatar content (image or fallback letter)
            Item {
                id: avatarContent
                anchors.centerIn: parent
                width: 72 * s; height: 72 * s
                visible: false // Hidden because OpacityMask renders it

                // Background fill
                Rectangle {
                    anchors.fill: parent
                    color: "#cc14101a"
                }

                Image {
                    id: avatarImg
                    anchors.fill: parent
                    source: (userHelper.currentItem && userHelper.currentItem.uIcon) ? userHelper.currentItem.uIcon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                    sourceSize.width: parent.width
                    sourceSize.height: parent.height
                }

                // Fallback: first letter of username
                Text {
                    anchors.centerIn: parent
                    text: {
                        var name = (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : "U";
                        return name.charAt(0).toUpperCase();
                    }
                    color: root.sunCream
                    font.family: pf.name
                    font.pixelSize: 28 * s
                    visible: avatarImg.status !== Image.Ready
                }
            }

            // Circular mask shape
            Rectangle {
                id: avatarMask
                anchors.centerIn: parent
                width: 72 * s; height: 72 * s
                radius: width / 2
                color: "white"
                visible: false
            }

            // Apply circular mask to avatar content
            OpacityMask {
                anchors.centerIn: parent
                width: 72 * s; height: 72 * s
                source: avatarContent
                maskSource: avatarMask
            }

            MouseArea {
                id: avatarMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() }
            }
        }

        // User Select
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: unt.implicitWidth; height: unt.implicitHeight
            Text {
                id: unt
                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "User")).toUpperCase()
                color: root.dynamicAccentForWallpaper(root.accent1); font.family: pf.name; font.pixelSize: 22 * s; font.letterSpacing: 4 * s
                layer.enabled: true; layer.effect: DropShadow { color: "#80000000"; radius: 4; samples: 8; horizontalOffset: 1; verticalOffset: 1 }
                opacity: unm.containsMouse ? 1.0 : 0.75
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Rectangle {
                anchors.bottom: unt.bottom; anchors.bottomMargin: -6 * s; anchors.horizontalCenter: parent.horizontalCenter
                width: unm.containsMouse ? parent.width : 0; height: 1 * s; color: root.readableAccent(root.accent1); opacity: 0.8
                Behavior on width { NumberAnimation { duration: 200 } }
            }
            MouseArea { id: unm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { if (typeof userModel !== "undefined" && userModel.rowCount() > 0) root.userIndex = (root.userIndex + 1) % userModel.rowCount() } }
        }

        // Pass Input
        Item {
            width: parent.width; height: 36 * s
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1 * s; color: root.readableAccent(root.accent3); opacity: pwd.activeFocus ? 1.0 : 0.4 }
            Rectangle { anchors.bottom: parent.bottom; width: pwd.activeFocus ? parent.width : 0; height: 2 * s; color: root.peachSky; anchors.horizontalCenter: parent.horizontalCenter; Behavior on width { NumberAnimation {duration: 300; easing.type: Easing.OutExpo} } }
            TextInput {
                id: pwd; anchors.fill: parent; color: root.peachSky; font.family: pf.name; font.pixelSize: 18 * s; font.letterSpacing: 4 * s
                echoMode: TextInput.Password; onTextEdited: err.text = ""; passwordCharacter: "─"; focus: true; clip: true; horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                cursorVisible: false; cursorDelegate: Item { width: 0; height: 0 }
                selectionColor: root.readableAccent(root.accent3)
                property bool wasClicked: false
                onActiveFocusChanged: if (!activeFocus && text.length === 0) wasClicked = false
                Keys.onReturnPressed: doLogin(); Keys.onEnterPressed: doLogin()
            }
            Text { 
                anchors.centerIn: parent; text: "password..."; color: root.readableAccent(root.accent3); font.family: pf.name; font.pixelSize: 14 * s; font.letterSpacing: 4 * s
                opacity: pwd.text.length === 0 ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutSine } }
            }
            Rectangle {
                id: customCursor
                width: 2 * s; height: 20 * s
                color: root.readableAccent(root.accent3)
                anchors.verticalCenter: parent.verticalCenter
                x: pwd.cursorRectangle.x
                visible: pwd.focus && (pwd.text.length > 0 || pwd.wasClicked)
                SequentialAnimation {
                    loops: Animation.Infinite; running: customCursor.visible
                    NumberAnimation { target: customCursor; property: "opacity"; from: 1; to: 0.05; duration: 450 }
                    NumberAnimation { target: customCursor; property: "opacity"; from: 0.05; to: 1; duration: 450 }
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pwd.forceActiveFocus()
                    pwd.wasClicked = true
                }
            }
        }

        // Navigation + Login Row (PREV - LOG IN - NEXT)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16 * s
            height: 36 * s

            // PREV Button
            Item {
                width: prevText.implicitWidth + 16 * s
                height: 36 * s
                visible: bgLoader.item ? true : false
                Rectangle {
                    anchors.fill: parent
                    color: prevMouse.containsMouse ? root.accent3 : "#cc14101a"
                    border.color: root.readableAccent(root.accent3)
                    border.width: 1
                    radius: 4 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    id: prevText
                    anchors.centerIn: parent
                    text: "◀ PREV"
                    color: prevMouse.containsMouse ? root.contrastText(root.accent3) : root.readableAccent(root.accent3)
                    font.family: pf.name
                    font.pixelSize: 11 * s
                    font.letterSpacing: 2 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (bgLoader.item) bgLoader.item.prevWallpaper() }
                }
            }

            // Login Button
            Item {
                width: 140 * s; height: 36 * s
                Rectangle { anchors.fill: parent; color: sbm.containsMouse ? root.accent3 : "#cc14101a"; border.color: root.readableAccent(root.accent3); border.width: 1; radius: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                Text { anchors.centerIn: parent; text: "LOG IN"; color: sbm.containsMouse ? root.contrastText(root.accent3) : root.readableAccent(root.accent3); font.family: pf.name; font.pixelSize: 12 * s; font.letterSpacing: 4 * s; Behavior on color { ColorAnimation { duration: 150 } } }
                MouseArea { id: sbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: doLogin() }
            }

            // NEXT Button
            Item {
                width: nextText.implicitWidth + 16 * s
                height: 36 * s
                visible: bgLoader.item ? true : false
                Rectangle {
                    anchors.fill: parent
                    color: nextMouse.containsMouse ? root.accent3 : "#cc14101a"
                    border.color: root.readableAccent(root.accent3)
                    border.width: 1
                    radius: 4 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                Text {
                    id: nextText
                    anchors.centerIn: parent
                    text: "NEXT ▶"
                    color: nextMouse.containsMouse ? root.contrastText(root.accent3) : root.readableAccent(root.accent3)
                    font.family: pf.name
                    font.pixelSize: 11 * s
                    font.letterSpacing: 2 * s
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (bgLoader.item) bgLoader.item.nextWallpaper() }
                }
            }
        }
        Text { id: err; text: ""; height: 12 * s; verticalAlignment: Text.AlignBottom; color: "#ff5555"; anchors.horizontalCenter: parent.horizontalCenter; font.family: pf.name; font.pixelSize: 12 * s }
    }

    // Top Island Panel (Unified Mode, Session, and Power Controls)
    Row {
        id: topIslandPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40 * s
        spacing: 12 * s
        opacity: root.ui
        z: 300

        property string openDropdown: "" // "", "mode", "power"

        // Helper function for session icons
        function getSessionIcon(sessionName) {
            if (!sessionName) return "sessions/default.svg";
            var name = sessionName.toLowerCase();
            if (name.indexOf("plasma") !== -1 || name.indexOf("kde") !== -1) return "sessions/plasma.svg";
            if (name.indexOf("hyprland") !== -1) return "sessions/hyprland.svg";
            if (name.indexOf("niri") !== -1) return "sessions/niri.svg";
            if (name.indexOf("sway") !== -1) return "sessions/sway.svg";
            if (name.indexOf("i3") !== -1) return "sessions/i3.svg";
            if (name.indexOf("gnome") !== -1) return "sessions/gnome.svg";
            if (name.indexOf("xfce") !== -1) return "sessions/xfce.svg";
            if (name.indexOf("cinnamon") !== -1) return "sessions/cinnamon.svg";
            if (name.indexOf("awesome") !== -1) return "sessions/awesome.svg";
            if (name.indexOf("bspwm") !== -1) return "sessions/bspwm.svg";
            if (name.indexOf("qtile") !== -1) return "sessions/qtile.svg";
            if (name.indexOf("dwm") !== -1) return "sessions/dwm.svg";
            if (name.indexOf("ubuntu") !== -1) return "sessions/ubuntu.svg";
            return "sessions/default.svg";
        }

        // Helper function for mode icons
        function getModeIcon(modeName) {
            var m = modeName ? modeName.toLowerCase() : "hybrid";
            if (m === "video") return "icons/video_mode.svg";
            if (m === "image" || m === "gambar") return "icons/image_mode.svg";
            if (m === "stay") return "icons/stay_default_mode.svg";
            return "icons/hybrid_mode.svg";
        }

        // Helper function for mode labels
        function getModeLabel(modeName) {
            var m = modeName ? modeName.toLowerCase() : "hybrid";
            if (m === "video") return "VIDEO";
            if (m === "image" || m === "gambar") return "IMAGE";
            if (m === "stay") return "STAY";
            return "HYBRID";
        }

        // 1. DYNAMIC WALLPAPER MODE SELECTOR
        Item {
            id: modeContainer
            width: modeBtn.width
            height: 36 * s
            property bool isOpen: topIslandPanel.openDropdown === "mode"

            // Active Mode Button (Solid)
            Rectangle {
                id: modeBtn
                height: 36 * s
                width: modeRow.implicitWidth + 30 * s
                color: (modeBtnMouse.containsMouse || modeContainer.isOpen) ? root.accent4 : "#cc14101a"
                border.color: root.readableAccent(root.accent4)
                border.width: 1
                radius: 8 * s
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 8 * s
                    Image {
                        source: topIslandPanel.getModeIcon(bgLoader.item ? bgLoader.item.activeMode : "hybrid")
                        width: 16 * s
                        height: 16 * s
                        sourceSize.width: width
                        sourceSize.height: height
                        fillMode: Image.PreserveAspectFit
                        anchors.verticalCenter: parent.verticalCenter
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: (modeBtnMouse.containsMouse || modeContainer.isOpen) ? root.contrastText(root.accent4) : root.readableAccent(root.accent4)
                        }
                    }
                    Text {
                        text: topIslandPanel.getModeLabel(bgLoader.item ? bgLoader.item.activeMode : "hybrid").toUpperCase()
                        color: (modeBtnMouse.containsMouse || modeContainer.isOpen) ? root.contrastText(root.accent4) : root.readableAccent(root.accent4)
                        font.family: pf.name
                        font.pixelSize: 11 * s
                        font.letterSpacing: 1 * s
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1.5 * s
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: modeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topIslandPanel.openDropdown = (modeContainer.isOpen ? "" : "mode")
                }
            }

            // Dropdown List (Other Modes)
            Column {
                anchors.top: parent.bottom
                anchors.topMargin: 6 * s
                anchors.left: parent.left
                width: modeBtn.width
                spacing: 6 * s
                visible: modeContainer.isOpen

                Repeater {
                    model: {
                        var active = bgLoader.item ? bgLoader.item.activeMode : "hybrid";
                        var list = ["hybrid", "video", "image", "stay"];
                        return list.filter(function(item) { return item !== active; });
                    }
                    delegate: Rectangle {
                        width: parent.width
                        height: 32 * s
                        color: optMouse.containsMouse ? root.accent4 : "#cc14101a"
                        border.color: root.readableAccent(root.accent4)
                        border.width: 1
                        radius: 8 * s
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 8 * s
                            Image {
                                source: topIslandPanel.getModeIcon(modelData)
                                width: 14 * s
                                height: 14 * s
                                sourceSize.width: width
                                sourceSize.height: height
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: optMouse.containsMouse ? root.contrastText(root.accent4) : root.readableAccent(root.accent4)
                                }
                            }
                            Text {
                                text: topIslandPanel.getModeLabel(modelData).toUpperCase()
                                color: optMouse.containsMouse ? root.contrastText(root.accent4) : root.readableAccent(root.accent4)
                                font.family: pf.name
                                font.pixelSize: 10 * s
                                font.letterSpacing: 1 * s
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 1.5 * s
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: optMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (bgLoader.item) {
                                    bgLoader.item.changeMode(modelData);
                                }
                                topIslandPanel.openDropdown = "";
                            }
                        }
                    }
                }
            }
        }

        // 2. SESSION CYCLE SELECTOR (No Dropdown - click to cycle)
        Item {
            id: sessionContainer
            visible: !root.isQuickshell
            width: sessionBtn.width
            height: 36 * s
            readonly property string activeSessionName: (sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "Session"

            Rectangle {
                id: sessionBtn
                height: 36 * s
                width: sessionRow.implicitWidth + 30 * s
                color: sessionBtnMouse.containsMouse ? root.accent5 : "#cc14101a"
                border.color: root.readableAccent(root.accent5)
                border.width: 1
                radius: 8 * s
                Behavior on color { ColorAnimation { duration: 150 } }

                Row {
                    id: sessionRow
                    anchors.centerIn: parent
                    spacing: 8 * s
                    Image {
                        source: topIslandPanel.getSessionIcon(sessionContainer.activeSessionName)
                        width: 16 * s
                        height: 16 * s
                        sourceSize.width: width
                        sourceSize.height: height
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color: sessionBtnMouse.containsMouse ? root.contrastText(root.accent5) : root.readableAccent(root.accent5)
                        }
                    }
                    Text {
                        text: sessionContainer.activeSessionName.toUpperCase()
                        color: sessionBtnMouse.containsMouse ? root.contrastText(root.accent5) : root.readableAccent(root.accent5)
                        font.family: pf.name
                        font.pixelSize: 11 * s
                        font.letterSpacing: 1 * s
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 1.5 * s
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: sessionBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                        }
                    }
                }
            }
        }

        // 3. POWER SELECTOR
        Item {
            id: powerContainer
            width: 36 * s
            height: 36 * s
            property bool isOpen: topIslandPanel.openDropdown === "power"

            // Power Icon Button (Solid)
            Rectangle {
                anchors.fill: parent
                color: (powerBtnMouse.containsMouse || powerContainer.isOpen) ? root.accent6 : "#cc14101a"
                border.color: root.readableAccent(root.accent6)
                border.width: 1
                radius: 8 * s
                Behavior on color { ColorAnimation { duration: 150 } }

                Image {
                    source: "icons/power_button.svg"
                    anchors.centerIn: parent
                    width: 20 * s
                    height: 20 * s
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: (powerBtnMouse.containsMouse || powerContainer.isOpen) ? root.contrastText(root.accent6) : root.readableAccent(root.accent6)
                    }
                }

                MouseArea {
                    id: powerBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: topIslandPanel.openDropdown = (powerContainer.isOpen ? "" : "power")
                }
            }

            // Dropdown List (Sleep, Shutdown, Reboot - Solid)
            Column {
                anchors.top: parent.bottom
                anchors.topMargin: 6 * s
                anchors.right: parent.right
                width: 130 * s
                spacing: 6 * s
                visible: parent.isOpen

                Repeater {
                    model: [
                        { l: "SLEEP", i: "icons/sleep.svg", a: 2 },
                        { l: "SHUTDOWN", i: "icons/shutdown.svg", a: 1 },
                        { l: "REBOOT", i: "icons/restart.svg", a: 0 }
                    ]
                    delegate: Rectangle {
                        width: parent.width
                        height: 32 * s
                        color: optPowerMouse.containsMouse ? root.accent6 : "#cc14101a"
                        border.color: root.readableAccent(root.accent6)
                        border.width: 1
                        radius: 6 * s
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8 * s
                            Image {
                                source: modelData.i
                                width: 14 * s
                                height: 14 * s
                                sourceSize.width: width
                                sourceSize.height: height
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: ColorOverlay {
                                    color: optPowerMouse.containsMouse ? root.contrastText(root.accent6) : root.readableAccent(root.accent6)
                                }
                            }
                            Text {
                                text: modelData.l
                                color: optPowerMouse.containsMouse ? root.contrastText(root.accent6) : root.readableAccent(root.accent6)
                                font.family: pf.name
                                font.pixelSize: 10 * s
                                font.letterSpacing: 1 * s
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.verticalCenterOffset: 1.5 * s
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: optPowerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                topIslandPanel.openDropdown = "";
                                if (modelData.a === 0) {
                                    if (typeof sddm !== "undefined") sddm.reboot();
                                } else if (modelData.a === 1) {
                                    if (typeof sddm !== "undefined") sddm.powerOff();
                                } else if (modelData.a === 2) {
                                    if (typeof sddm !== "undefined" && sddm.canSuspend) sddm.suspend();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Close any open dropdown when clicking on background
    MouseArea {
        anchors.fill: parent
        z: 150
        enabled: topIslandPanel.openDropdown !== ""
        onClicked: topIslandPanel.openDropdown = ""
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() { err.text = "ACCESS DENIED"; pwd.text = ""; pwd.focus = true }
    }
    function doLogin() { var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : ""); if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex) }
}
