import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import QtQuick.LocalStorage
import SddmComponents 2.0
import "colors.js" as Colors

// Modern Minimalist SDDM Theme with Sliding Behind-Card Drawer
Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: '#11111b'
    opacity: 1

    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    readonly property real s: Screen.height / 768
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0

    // ===== INTRO / LOCK-UNLOCK STATE =====
    property bool clockCentered: true      // true = lock screen / clock-only, false = login UI active
    property real loginUiOpacity: 0        // opacity of login card & controls
    property real loginUiScale: 0.85       // scale of login card & controls (bouncy reveal/hide)
    property bool isPasswordVisible: false // toggle clear text / masked password
    property bool drawerOpen: false        // toggle sliding behind-card drawer
    property bool powerMenuOpen: false     // toggle power popup menu

    // ===== CATPPUCCIN MOCHA / SERPANTINUM PALETTE =====
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color overlay0: "#6c7086"
    readonly property color overlay1: "#7f849c"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color blue: "#89b4fa"
    readonly property color mauve: "#cba6f7"
    readonly property color peach: "#fab387"
    readonly property color red: "#f38ba8"
    readonly property color green: "#a6e3a1"

    // Dynamic Accent Colors (extracted from wallpaper/video via colors.js or realtime extractor)
    property color accent1: mauve
    property color accent2: blue
    property color accent3: peach
    property color accent4: green
    property color accent5: red
    property color accent6: mauve

    Behavior on accent1 { ColorAnimation { duration: 400 } }
    Behavior on accent2 { ColorAnimation { duration: 400 } }
    Behavior on accent3 { ColorAnimation { duration: 400 } }
    Behavior on accent4 { ColorAnimation { duration: 400 } }
    Behavior on accent5 { ColorAnimation { duration: 400 } }
    Behavior on accent6 { ColorAnimation { duration: 400 } }

    function contrastText(accentColor) {
        var r = accentColor.r;
        var g = accentColor.g;
        var b = accentColor.b;
        var luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        return luminance > 0.65 ? root.crust : "#ffffff";
    }

    function readableAccent(accentColor) {
        var r = accentColor.r;
        var g = accentColor.g;
        var b = accentColor.b;
        var max = Math.max(r, g, b);
        var lum = 0.299 * r + 0.587 * g + 0.114 * b;
        if (max >= 0.55 || lum >= 0.28) {
            return accentColor;
        }
        var boost = 0.6 / Math.max(max, 0.05);
        return Qt.rgba(Math.min(1.0, r * boost), Math.min(1.0, g * boost), Math.min(1.0, b * boost), 1.0);
    }

    function getBestAccents(palette) {
        if (!palette || palette.length === 0) return [root.mauve, root.blue];
        var scored = [];
        for (var i = 0; i < palette.length; i++) {
            var c = Qt.color(palette[i]);
            var r = c.r, g = c.g, b = c.b;
            var max = Math.max(r, g, b);
            var min = Math.min(r, g, b);
            var sat = max === 0 ? 0 : (max - min) / max;
            var lum = 0.299 * r + 0.587 * g + 0.114 * b;
            var score = sat * 2.0 + (lum >= 0.25 && lum <= 0.85 ? 1.5 : (lum < 0.25 ? lum * 4 : (1.0 - lum) * 2));
            scored.push({ color: palette[i], score: score });
        }
        scored.sort(function(a, b) { return b.score - a.score; });
        var first = scored[0].color;
        var second = scored.length > 1 ? scored[1].color : first;
        for (var j = 1; j < scored.length; j++) {
            if (scored[j].color !== first) {
                second = scored[j].color;
                break;
            }
        }
        return [first, second];
    }

    readonly property color primaryAccent: readableAccent(accent1)
    readonly property color secondaryAccent: readableAccent(accent2)

    // Card & Sliding Behind-Card Colors (Subtly tinted by wallpaper accent for cohesive aesthetic)
    readonly property color cardBg: Qt.rgba(
        base.r + primaryAccent.r * 0.08,
        base.g + primaryAccent.g * 0.08,
        base.b + primaryAccent.b * 0.08,
        0.94
    )
    readonly property color cardBorder: Qt.rgba(
        primaryAccent.r * 0.5 + surface1.r * 0.5,
        primaryAccent.g * 0.5 + surface1.g * 0.5,
        primaryAccent.b * 0.5 + surface1.b * 0.5,
        0.55
    )
    readonly property color backCardBg: Qt.rgba(
        surface0.r + primaryAccent.r * 0.06,
        surface0.g + primaryAccent.g * 0.06,
        surface0.b + primaryAccent.b * 0.06,
        0.92
    )
    readonly property color backCardBorder: Qt.rgba(
        primaryAccent.r * 0.35 + surface1.r * 0.65,
        primaryAccent.g * 0.35 + surface1.g * 0.65,
        primaryAccent.b * 0.35 + surface1.b * 0.65,
        0.45
    )
    readonly property color inputBg: Qt.rgba(
        surface0.r + primaryAccent.r * 0.04,
        surface0.g + primaryAccent.g * 0.04,
        surface0.b + primaryAccent.b * 0.04,
        0.85
    )
    readonly property color inputBorder: Qt.rgba(
        surface1.r + primaryAccent.r * 0.2,
        surface1.g + primaryAccent.r * 0.2,
        surface1.b + primaryAccent.r * 0.2,
        0.5
    )
    readonly property color inputBorderActive: primaryAccent
    readonly property color btnCtaBg: primaryAccent
    readonly property color btnCtaHover: Qt.lighter(primaryAccent, 1.15)
    readonly property color btnCtaText: contrastText(primaryAccent)

    property string currentAccentFile: ""

    function updateAccentColor(filePath) {
        if (!filePath) return;
        var filename = filePath.substring(filePath.lastIndexOf('/') + 1);
        if (filename === currentAccentFile) {
            return;
        }
        currentAccentFile = filename;
        if (Colors && Colors.colorMap && Colors.colorMap[filename]) {
            var palette = Colors.colorMap[filename];
            if (palette && palette.length >= 6) {
                var best = root.getBestAccents(palette);
                root.accent1 = best[0];
                root.accent2 = best[1];
                root.accent3 = palette[2];
                root.accent4 = palette[3];
                root.accent5 = palette[4];
                root.accent6 = palette[5];
                console.log("Accent colors updated from cache: " + filename + " -> primary=" + best[0] + ", secondary=" + best[1]);
                return;
            }
        }
        var ext = filename.split('.').pop().toLowerCase();
        if (ext === "png" || ext === "jpg" || ext === "jpeg" || ext === "webp" || ext === "gif") {
            realtimeExtractor.imageSource = filePath;
        } else {
            root.accent1 = root.mauve;
            root.accent2 = root.blue;
            root.accent3 = root.peach;
            root.accent4 = root.green;
            root.accent5 = root.red;
            root.accent6 = root.mauve;
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
                var pal = [rgbAt(0), rgbAt(1), rgbAt(2), rgbAt(3), rgbAt(4), rgbAt(5)];
                var best = root.getBestAccents(pal);
                root.accent1 = best[0];
                root.accent2 = best[1];
                root.accent3 = pal[2];
                root.accent4 = pal[3];
                root.accent5 = pal[4];
                root.accent6 = pal[5];
            } catch (e) {
                root.accent1 = root.mauve;
                root.accent2 = root.blue;
                root.accent3 = root.peach;
                root.accent4 = root.green;
                root.accent5 = root.red;
                root.accent6 = root.mauve;
            }
        }
    }

    property string activeWallpaperPath: bgLoader.item ? bgLoader.item.selectedFile : ""
    onActiveWallpaperPathChanged: {
        root.updateAccentColor(activeWallpaperPath);
    }

    Timer {
        id: initialColorTimer
        interval: 200
        running: true
        repeat: false
        onTriggered: {
            if (bgLoader.item) {
                root.updateAccentColor(bgLoader.item.selectedFile);
            }
        }
    }

    // Database Persistence
    function getSetting(key, defaultVal) {
        try {
            var db = LocalStorage.openDatabaseSync("NdynamicallySddmDB", "1.0", "Database for ndynamically-sddm settings", 100000);
            var val = defaultVal;
            db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, val TEXT)');
                var rs = tx.executeSql('SELECT val FROM settings WHERE key=?', [key]);
                if (rs.rows.length > 0) {
                    val = rs.rows.item(0).val;
                }
            });
            return val;
        } catch (e) {
            return defaultVal;
        }
    }

    function setSetting(key, val) {
        try {
            var db = LocalStorage.openDatabaseSync("NdynamicallySddmDB", "1.0", "Database for ndynamically-sddm settings", 100000);
            db.transaction(function(tx) {
                tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, val TEXT)');
                tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?, ?)', [key, val]);
            });
        } catch (e) {
        }
    }

    readonly property string defaultCardPos: (typeof config !== "undefined" && config.cardPosition) ? config.cardPosition.toLowerCase() : "center"
    readonly property string defaultCardAlign: (typeof config !== "undefined" && config.cardAlignment) ? config.cardAlignment.toLowerCase() : "center"

    property string cardPosition: getSetting("cardPosition", defaultCardPos)
    property string cardAlignment: getSetting("cardAlignment", defaultCardAlign)

    readonly property bool defaultEnableBlur: (typeof config !== "undefined" && typeof config.enableBlur !== "undefined") ? (config.enableBlur === "true" || config.enableBlur === true) : true
    readonly property bool defaultEnableGlow: (typeof config !== "undefined" && typeof config.enableGlow !== "undefined") ? (config.enableGlow === "true" || config.enableGlow === true) : true

    property bool enableBlur: getSetting("enableBlur", defaultEnableBlur ? "true" : "false") === "true"
    property bool enableGlow: getSetting("enableGlow", defaultEnableGlow ? "true" : "false") === "true"

    readonly property var positionOptions: [
        "center",
        "top",
        "top-right",
        "right",
        "bottom-right",
        "bottom",
        "bottom-left",
        "left",
        "top-left"
    ]

    function getPositionLabel(pos) {
        switch (pos) {
            case "center": return "Center";
            case "top": return "Top";
            case "top-right": return "Top Right";
            case "right": return "Right";
            case "bottom-right": return "Bottom Right";
            case "bottom": return "Bottom";
            case "bottom-left": return "Bottom Left";
            case "left": return "Left";
            case "top-left": return "Top Left";
            default: return "Center";
        }
    }

    readonly property var alignmentOptions: ["center", "left", "right"]

    function getAlignmentLabel(al) {
        switch (al) {
            case "left": return "Left";
            case "right": return "Right";
            case "center": return "Center";
            default: return "Center";
        }
    }

    FontLoader { id: pf; source: "font/PixelifySans-Bold.ttf" }
    FontLoader { id: clock; source: "font/DIN-Bold.ttf" }
    FontLoader { id: dinBold; source: "font/DIN-Bold.ttf" }
    FontLoader { id: dinRegular; source: "font/DIN-Regular.ttf" }

    ListView { id: sessionHelper; model: typeof sessionModel !== "undefined" ? sessionModel : null; currentIndex: root.sessionIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string sName: model.name || "" } }
    ListView { id: userHelper; model: typeof userModel !== "undefined" ? userModel : null; currentIndex: root.userIndex; opacity: 0; width: 100; height: 100; z: -100; delegate: Item { property string uName: model.realName || model.name || ""; property string uLogin: model.name || ""; property string uIcon: model.icon || "" } }

    Timer {
        id: focusPwdOnce
        interval: 250
        running: false
        repeat: false
        onTriggered: {
            if (!root.clockCentered) pwd.forceActiveFocus();
        }
    }

    Timer {
        id: idleTimer
        interval: 20000
        repeat: false
        onTriggered: {
            root.goToLockScreen();
        }
    }

    function resetIdleTimer() {
        if (!root.clockCentered) {
            idleTimer.restart();
        }
    }

    Component.onCompleted: {
        keyboard.numLock = true;
    }

    Keys.onEscapePressed: {
        if (root.powerMenuOpen) {
            root.powerMenuOpen = false;
            return;
        }
        if (root.drawerOpen) {
            root.drawerOpen = false;
            return;
        }
        if (!clockCentered) {
            goToLockScreen();
        } else {
            wakeToLogin();
        }
    }

    Keys.onPressed: (event) => {
        root.resetIdleTimer();

        if (pwd.activeFocus) return;

        if (event.key === Qt.Key_Backspace) {
            if (clockCentered) {
                wakeToLogin();
            }
            pwd.forceActiveFocus();
            if (pwd.text.length > 0) {
                pwd.text = pwd.text.slice(0, -1);
            }
            event.accepted = true;
            return;
        }

        if (event.text && event.text.length > 0 && /^[\x20-\x7E]$/.test(event.text)) {
            if (clockCentered) {
                wakeToLogin();
            }
            pwd.forceActiveFocus();
            pwd.text += event.text;
            event.accepted = true;
        }
    }

    SequentialAnimation {
        id: wakeSequence
        ScriptAction {
            script: {
                loginHideAnim.stop();
                root.clockCentered = false;
            }
        }
        PauseAnimation { duration: 520 }
        ScriptAction {
            script: {
                loginRevealAnim.start();
                focusPwdOnce.restart();
                idleTimer.restart();
            }
        }
    }

    function wakeToLogin() {
        if (!clockCentered && root.loginUiOpacity > 0.9) return;
        wakeSequence.restart();
    }

    function goToLockScreen() {
        wakeSequence.stop();
        loginRevealAnim.stop();
        loginHideAnim.restart();
    }

    ParallelAnimation {
        id: loginRevealAnim
        NumberAnimation {
            target: root; property: "loginUiOpacity"
            from: root.loginUiOpacity; to: 1.0; duration: 380; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "loginUiScale"
            from: root.loginUiScale; to: 1.0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.3
        }
    }

    SequentialAnimation {
        id: loginHideAnim
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "loginUiOpacity"
                from: root.loginUiOpacity; to: 0.0; duration: 250; easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: root; property: "loginUiScale"
                from: root.loginUiScale; to: 0.85; duration: 250; easing.type: Easing.InBack; easing.overshoot: 1.15
            }
        }
        ScriptAction {
            script: {
                clockCentered = true;
                pwd.focus = false;
                root.forceActiveFocus();
                root.powerMenuOpen = false;
                root.drawerOpen = false;
                idleTimer.stop();
            }
        }
    }

    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 1200; easing.type: Easing.OutSine }
    NumberAnimation {
        id: rootFadeIn
        target: bgLoader
        property: "opacity"
        from: 0
        to: 1
        duration: 700
        easing.type: Easing.OutQuad
    }

    SequentialAnimation {
        id: introSequence
        PauseAnimation { duration: 250 }
        ScriptAction { script: fadeAnim.start() }
        PauseAnimation { duration: 600 }
        ScriptAction { script: root.clockCentered = false }
        PauseAnimation { duration: 600 }
        ScriptAction { script: loginRevealAnim.start() }
        ScriptAction { script: focusPwdOnce.restart() }
        ScriptAction { script: idleTimer.restart() }
    }

    Loader {
        id: bgLoader
        anchors.fill: parent
        source: "BackgroundVideo.qml"
        opacity: 0
        layer.enabled: root.enableBlur
        layer.effect: FastBlur {
            radius: root.enableBlur ? (root.clockCentered ? 20 : 6) : 0
            Behavior on radius {
                NumberAnimation { duration: 700; easing.type: Easing.InOutQuint }
            }
        }
        onLoaded: {
            if (item) {
                root.updateAccentColor(item.selectedFile);
                item.backgroundReady.connect(function() {
                    rootFadeIn.start();
                    introSequence.start();
                });
                if (item.backgroundReadyFlag) {
                    rootFadeIn.start();
                    introSequence.start();
                }
            }
        }
    }

    Connections {
        target: bgLoader.item
        function onSelectedFileChanged() {
            if (bgLoader.item) {
                root.updateAccentColor(bgLoader.item.selectedFile);
            }
        }
    }

    // Subtle dark backdrop dimmer (Opsi B: redup tipis & cerah)
    Rectangle {
        anchors.fill: parent
        color: root.crust
        opacity: root.clockCentered ? 0.20 : 0.15
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    }

    // Click anywhere during clock-centered lockscreen to wake up
    MouseArea {
        anchors.fill: parent
        enabled: root.clockCentered
        onClicked: root.wakeToLogin()
        z: 40
    }

    // Vignette Gradients — sangat tipis hanya untuk kontras teks
    Rectangle { anchors.top: parent.top; width: parent.width; height: 100 * s; gradient: Gradient { GradientStop { position: 0.0; color: "#25000000" } GradientStop { position: 1.0; color: "transparent" } } }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 120 * s; gradient: Gradient { GradientStop { position: 0.0; color: "transparent" } GradientStop { position: 1.0; color: "#30000000" } } }

    // ============================================================
    // CLOCK UNIT (Never clips text, Stably positioned at Top-Left)
    // ============================================================
    Item {
        anchors.fill: parent
        z: 50

        readonly property real clockTargetX: root.clockCentered ? (parent.width - clockColumn.width) / 2 : 48 * s
        readonly property real clockTargetY: {
            if (root.clockCentered) return (parent.height - clockColumn.height) / 2;
            if (root.cardPosition === "top-left") {
                return parent.height - clockColumn.height - 48 * s;
            }
            return 48 * s;
        }

        Column {
            id: clockColumn
            spacing: 4 * s
            opacity: root.ui

            x: parent.clockTargetX
            y: parent.clockTargetY
            Behavior on x { NumberAnimation { duration: 600; easing.type: Easing.InOutQuint } }
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.InOutQuint } }

            Text {
                id: clk; text: Qt.formatTime(new Date(), "HH.mm")
                color: root.text
                font.family: clock.name
                font.pixelSize: (root.clockCentered ? 140 : 80) * s
                font.letterSpacing: -2 * s
                Behavior on font.pixelSize { NumberAnimation { duration: 600; easing.type: Easing.InOutQuint } }
                Timer { interval: 1000; running: true; repeat: true; onTriggered: clk.text = Qt.formatTime(new Date(), "HH.mm") }
                layer.enabled: root.enableGlow
                layer.effect: DropShadow { color: "#aa000000"; radius: 8; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            }
            Text {
                id: dateText
                text: Qt.formatDate(new Date(), "dddd, MMMM d").toUpperCase()
                color: root.primaryAccent
                Behavior on color { ColorAnimation { duration: 300 } }
                font.family: dinBold.name
                font.pixelSize: 13 * s
                font.letterSpacing: 2 * s
                layer.enabled: root.enableGlow
                layer.effect: DropShadow { color: "#aa000000"; radius: 4; samples: 8; horizontalOffset: 2 * s; verticalOffset: 2 * s }
            }
        }

        MouseArea {
            anchors.fill: clockColumn
            enabled: !root.clockCentered
            onClicked: root.goToLockScreen()
            z: 1
        }
    }

    // ============================================================
    // SERPANTINUM BOTTOM TRAY (Power & Session)
    // Sits at Bottom-Right, but dynamically docks to Bottom-Left
    // if the Login Card is positioned at Bottom-Right. ZERO collision!
    // ============================================================
    Item {
        id: bottomTray
        readonly property bool trayDockLeft: root.cardPosition === "bottom-right"

        x: trayDockLeft ? 32 * s : (root.width - width - 32 * s)
        y: root.height - height - 24 * s
        height: 44 * s
        width: trayRow.implicitWidth
        opacity: root.loginUiOpacity
        scale: root.loginUiScale
        transformOrigin: bottomTray.trayDockLeft ? Item.BottomLeft : Item.BottomRight
        visible: opacity > 0.001
        enabled: !root.clockCentered && opacity > 0.5
        z: 300

        Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

        Row {
            id: trayRow
            spacing: 10 * s
            anchors.verticalCenter: parent.verticalCenter

            // Session Selector Pill
            Rectangle {
                id: sessionBtn
                visible: !root.isQuickshell
                height: 42 * s
                width: sessionContent.implicitWidth + 24 * s
                radius: 12 * s
                color: sessionMouse.containsMouse ? root.surface2 : root.surface0
                border.color: root.surface1
                border.width: 1 * s
                Behavior on color { ColorAnimation { duration: 150 } }

                readonly property string activeSessionName: (sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "Session"

                Row {
                    id: sessionContent
                    anchors.centerIn: parent
                    spacing: 8 * s

                    Image {
                        source: getSessionIcon(sessionBtn.activeSessionName)
                        width: 16 * s
                        height: 16 * s
                        sourceSize.width: width
                        sourceSize.height: height
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: root.text }
                    }

                    Text {
                        text: sessionBtn.activeSessionName.toUpperCase()
                        color: root.text
                        font.family: dinBold.name
                        font.pixelSize: 11 * s
                        font.letterSpacing: 1 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resetIdleTimer();
                        if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                            root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount();
                        }
                    }
                }
            }

            // Power Toggle Button
            Rectangle {
                id: powerToggleBtn
                width: 42 * s
                height: 42 * s
                radius: 12 * s
                color: (powerToggleMouse.containsMouse || root.powerMenuOpen) ? root.surface2 : root.surface0
                border.color: root.powerMenuOpen ? root.red : root.surface1
                border.width: root.powerMenuOpen ? 2 * s : 1 * s
                scale: powerToggleMouse.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 120 } }
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
                    layer.effect: ColorOverlay { color: root.powerMenuOpen ? root.text : root.red }
                }

                MouseArea {
                    id: powerToggleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resetIdleTimer();
                        root.powerMenuOpen = !root.powerMenuOpen;
                    }
                }
            }
        }

        // Power Popup Menu
        Rectangle {
            id: powerPopup
            anchors.bottom: parent.top
            anchors.bottomMargin: 12 * s
            anchors.right: bottomTray.trayDockLeft ? undefined : parent.right
            anchors.left: bottomTray.trayDockLeft ? parent.left : undefined
            width: 170 * s
            height: root.powerMenuOpen ? (powerCol.implicitHeight + 20 * s) : 0
            radius: 14 * s
            clip: true
            opacity: root.powerMenuOpen ? 1 : 0
            visible: height > 0 || opacity > 0
            color: root.base
            border.color: root.surface1
            border.width: 1 * s

            layer.enabled: root.enableGlow
            layer.effect: DropShadow {
                color: "#aa000000"
                radius: 20
                samples: 16
                horizontalOffset: 0
                verticalOffset: 6 * s
            }

            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            Column {
                id: powerCol
                anchors.top: parent.top
                anchors.topMargin: 10 * s
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10 * s
                spacing: 6 * s

                // 1. Suspend
                Rectangle {
                    width: parent.width
                    height: 34 * s
                    radius: 8 * s
                    color: suspMouse.containsMouse ? root.surface2 : root.surface0
                    border.color: root.surface1
                    border.width: 1 * s

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8 * s
                        Image {
                            source: "icons/sleep.svg"
                            width: 15 * s
                            height: 15 * s
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: root.primaryAccent }
                        }
                        Text {
                            text: "Suspend"
                            color: root.text
                            font.family: dinRegular.name
                            font.pixelSize: 12 * s
                        }
                    }

                    MouseArea {
                        id: suspMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerMenuOpen = false;
                            if (typeof sddm !== "undefined" && sddm.canSuspend) sddm.suspend();
                        }
                    }
                }

                // 2. Reboot
                Rectangle {
                    width: parent.width
                    height: 34 * s
                    radius: 8 * s
                    color: rebootMouse.containsMouse ? root.surface2 : root.surface0
                    border.color: root.surface1
                    border.width: 1 * s

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8 * s
                        Image {
                            source: "icons/restart.svg"
                            width: 15 * s
                            height: 15 * s
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: root.secondaryAccent }
                        }
                        Text {
                            text: "Reboot"
                            color: root.text
                            font.family: dinRegular.name
                            font.pixelSize: 12 * s
                        }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerMenuOpen = false;
                            if (typeof sddm !== "undefined") sddm.reboot();
                        }
                    }
                }

                // 3. Power Off
                Rectangle {
                    width: parent.width
                    height: 34 * s
                    radius: 8 * s
                    color: powerOffMouse.containsMouse ? root.surface2 : root.surface0
                    border.color: root.surface1
                    border.width: 1 * s

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8 * s
                        Image {
                            source: "icons/shutdown.svg"
                            width: 15 * s
                            height: 15 * s
                            sourceSize.width: width
                            sourceSize.height: height
                            fillMode: Image.PreserveAspectFit
                            layer.enabled: true
                            layer.effect: ColorOverlay { color: root.red }
                        }
                        Text {
                            text: "Shut Down"
                            color: root.text
                            font.family: dinRegular.name
                            font.pixelSize: 12 * s
                        }
                    }

                    MouseArea {
                        id: powerOffMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.powerMenuOpen = false;
                            if (typeof sddm !== "undefined") sddm.powerOff();
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 250
        enabled: root.powerMenuOpen
        onClicked: {
            root.resetIdleTimer();
            root.powerMenuOpen = false;
        }
    }

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

    // ============================================================
    // LOGIN CARD & SLIDING BEHIND-CARD DRAWER
    // Main Card is clean, solid, and modern (Catppuccin Mocha).
    // The settings drawer slides out smoothly from behind the main card!
    // ============================================================
    Item {
        id: cardWrapper
        width: mainCard.width + (root.drawerOpen ? (backCard.width - 24 * s) : 0) + 24 * s
        height: mainCard.height
        opacity: root.loginUiOpacity
        scale: root.loginUiScale
        transformOrigin: Item.Center
        visible: opacity > 0.001
        enabled: !root.clockCentered && opacity > 0.5
        z: 200

        readonly property real cardMargin: 48 * s
        readonly property real extraWidth: root.drawerOpen ? (backCard.width - 24 * s) : 0

        // 9 Positions: Center, Left, Right, Top, Bottom, and all Corners
        readonly property real targetX: {
            var rightX = root.width - mainCard.width - extraWidth - cardMargin;
            switch (root.cardPosition) {
                case "top-left":
                case "left":
                case "bottom-left":
                    return cardMargin;
                case "top-right":
                case "right":
                case "bottom-right":
                    return rightX;
                case "top":
                case "bottom":
                case "center":
                default:
                    return (root.width - mainCard.width - extraWidth) / 2;
            }
        }

        readonly property real targetY: {
            var bottomY = root.height - mainCard.height - cardMargin;
            switch (root.cardPosition) {
                case "top-left":
                case "top":
                case "top-right":
                    return cardMargin;
                case "bottom-left":
                case "bottom":
                case "bottom-right":
                    return bottomY;
                case "left":
                case "right":
                case "center":
                default:
                    return (root.height - mainCard.height) / 2;
            }
        }

        x: targetX
        y: targetY
        Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

        // ------------------------------------------------------------
        // SLIDING BACK CARD (Card di belakang yang ke-geser)
        // Same height as mainCard ("pres" / flush at top & bottom)
        // Left side corners rounded with 16px to match mainCard so NO corners peek out when closed
        // Closed: sits at x = 20px inside mainCard, completely hidden!
        // Open: slides out to the right, overlapping 24px under mainCard
        // 2-column layout horizontally ("panjang ke samping")
        // ------------------------------------------------------------
        Rectangle {
            id: backCard
            z: 1
            anchors.verticalCenter: mainCard.verticalCenter
            width: 260 * s
            height: mainCard.height
            topRightRadius: 14 * s
            bottomRightRadius: 14 * s
            topLeftRadius: 16 * s
            bottomLeftRadius: 16 * s
            color: root.backCardBg
            border.color: root.backCardBorder
            border.width: 1 * s

            Behavior on color { ColorAnimation { duration: 300 } }
            Behavior on border.color { ColorAnimation { duration: 300 } }

            // Closed: completely tucked 20px inside mainCard (x = 280 - 260 = 20 * s)
            // Open: slides out to the right, overlapping 24px under mainCard
            x: root.drawerOpen ? (mainCard.width - 24 * s) : (mainCard.width - width)

            Behavior on x { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }

            layer.enabled: root.drawerOpen && root.enableGlow
            layer.effect: DropShadow {
                color: "#aa000000"
                radius: 18
                samples: 16
                horizontalOffset: 2 * s
                verticalOffset: 4 * s
            }

            // Content inside the sliding back card (2 Horizontal Columns)
            Item {
                anchors.fill: parent
                anchors.leftMargin: 34 * s  // 24px tucked overlap + 10px margin
                anchors.topMargin: 14 * s
                anchors.bottomMargin: 14 * s
                anchors.rightMargin: 10 * s
                opacity: root.drawerOpen ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Row {
                    anchors.fill: parent
                    spacing: 10 * s

                    // ===== COLUMN 1: Mode, Transition, Alignment =====
                    Column {
                        width: (parent.width - 10 * s) / 2
                        anchors.top: parent.top
                        spacing: 8 * s

                        // 1. Mode Selector
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Mode"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }
                            Rectangle {
                                width: parent.width
                                height: 26 * s
                                radius: 7 * s
                                color: modeBtnMouse.containsMouse ? root.surface2 : root.base
                                border.color: modeBtnMouse.containsMouse ? root.primaryAccent : root.backCardBorder
                                border.width: 1 * s
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        var m = bgLoader.item ? bgLoader.item.activeMode : "hybrid";
                                        if (m === "video") return "Video";
                                        if (m === "image" || m === "gambar") return "Image";
                                        if (m === "stay") return "Stay";
                                        return "Hybrid";
                                    }
                                    color: root.text
                                    font.family: dinBold.name
                                    font.pixelSize: 11 * s
                                }

                                MouseArea {
                                    id: modeBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.resetIdleTimer();
                                        var modes = ["stay", "hybrid", "video", "image"];
                                        var current = bgLoader.item ? bgLoader.item.activeMode : "hybrid";
                                        var idx = modes.indexOf(current);
                                        var nextMode = modes[(idx + 1) % modes.length];
                                        if (bgLoader.item) bgLoader.item.changeMode(nextMode);
                                    }
                                }
                            }
                        }

                        // 2. Transition Selector
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Transition"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }
                            Rectangle {
                                width: parent.width
                                height: 26 * s
                                radius: 7 * s
                                color: transBtnMouse.containsMouse ? root.surface2 : root.base
                                border.color: transBtnMouse.containsMouse ? root.primaryAccent : root.backCardBorder
                                border.width: 1 * s
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        var t = bgLoader.item ? bgLoader.item.activeTransition : "none";
                                        if (t === "none") return "None";
                                        if (t === "fade") return "Fade";
                                        if (t === "wipe") return "Wipe";
                                        if (t === "circle") return "Circle";
                                        return t;
                                    }
                                    color: root.text
                                    font.family: dinBold.name
                                    font.pixelSize: 11 * s
                                }

                                MouseArea {
                                    id: transBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.resetIdleTimer();
                                        if (bgLoader.item) bgLoader.item.cycleTransition();
                                    }
                                }
                            }
                        }

                        // 3. Alignment Selector
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Alignment"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }
                            Rectangle {
                                width: parent.width
                                height: 26 * s
                                radius: 7 * s
                                color: alignBtnMouse.containsMouse ? root.surface2 : root.base
                                border.color: alignBtnMouse.containsMouse ? root.primaryAccent : root.backCardBorder
                                border.width: 1 * s
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: root.getAlignmentLabel(root.cardAlignment)
                                    color: root.text
                                    font.family: dinBold.name
                                    font.pixelSize: 11 * s
                                }

                                MouseArea {
                                    id: alignBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.resetIdleTimer();
                                        var idx = root.alignmentOptions.indexOf(root.cardAlignment);
                                        root.cardAlignment = root.alignmentOptions[(idx + 1) % root.alignmentOptions.length];
                                        root.setSetting("cardAlignment", root.cardAlignment);
                                    }
                                }
                            }
                        }
                    }

                    // ===== COLUMN 2: Position (3×3 Grid), Wallpaper Nav =====
                    Column {
                        width: (parent.width - 12 * s) / 2
                        anchors.top: parent.top
                        spacing: 8 * s

                        // Position Card (3×3 Grid Selector)
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Position"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }

                            // 3×3 visual grid — each cell = a screen position
                            Grid {
                                id: posGrid
                                columns: 3
                                rows: 3
                                spacing: 3 * s
                                width: parent.width

                                readonly property var posMap: [
                                    "top-left", "top", "top-right",
                                    "left", "center", "right",
                                    "bottom-left", "bottom", "bottom-right"
                                ]
                                readonly property real cellW: (width - 6 * s) / 3
                                readonly property real cellH: 18 * s

                                Repeater {
                                    model: 9
                                    Rectangle {
                                        width: posGrid.cellW
                                        height: posGrid.cellH
                                        radius: 4 * s
                                        color: {
                                            var pos = posGrid.posMap[index];
                                            if (root.cardPosition === pos) return root.primaryAccent;
                                            return posGridMouse.containsMouse ? root.surface2 : root.base;
                                        }
                                        border.color: root.cardPosition === posGrid.posMap[index] ? root.primaryAccent : root.surface1
                                        border.width: 1 * s
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        // Small dot indicator
                                        Rectangle {
                                            anchors.centerIn: parent
                                            width: 4 * s
                                            height: 4 * s
                                            radius: 2 * s
                                            color: root.cardPosition === posGrid.posMap[index] ? root.crust : root.overlay0
                                        }

                                        MouseArea {
                                            id: posGridMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.resetIdleTimer();
                                                root.cardPosition = posGrid.posMap[index];
                                                root.setSetting("cardPosition", root.cardPosition);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Wallpaper Navigation
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Wallpaper"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }
                            Row {
                                width: parent.width
                                spacing: 6 * s

                                Rectangle {
                                    width: (parent.width - 6 * s) / 2
                                    height: 25 * s
                                    radius: 6 * s
                                    color: prevWpMouse.containsMouse ? root.surface2 : root.base
                                    border.color: prevWpMouse.containsMouse ? root.primaryAccent : root.backCardBorder
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "◀ Prev"
                                        color: root.text
                                        font.family: dinRegular.name
                                        font.pixelSize: 10 * s
                                    }

                                    MouseArea {
                                        id: prevWpMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.resetIdleTimer();
                                            if (bgLoader.item) bgLoader.item.prevWallpaper();
                                        }
                                    }
                                }

                                Rectangle {
                                    width: (parent.width - 6 * s) / 2
                                    height: 25 * s
                                    radius: 6 * s
                                    color: nextWpMouse.containsMouse ? root.surface2 : root.base
                                    border.color: nextWpMouse.containsMouse ? root.primaryAccent : root.backCardBorder
                                    border.width: 1 * s

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Next ▶"
                                        color: root.text
                                        font.family: dinRegular.name
                                        font.pixelSize: 10 * s
                                    }

                                    MouseArea {
                                        id: nextWpMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.resetIdleTimer();
                                            if (bgLoader.item) bgLoader.item.nextWallpaper();
                                        }
                                    }
                                }
                            }
                        }

                        // Effects Toggles (Blur & Glow)
                        Column {
                            width: parent.width
                            spacing: 3 * s
                            Text {
                                text: "Effects"
                                color: root.subtext0
                                font.family: dinRegular.name
                                font.pixelSize: 10 * s
                            }
                            Row {
                                width: parent.width
                                spacing: 6 * s

                                // 1. Blur Toggle Pill
                                Rectangle {
                                    width: (parent.width - 6 * s) / 2
                                    height: 25 * s
                                    radius: 6 * s
                                    color: root.enableBlur ? (blurMouse.containsMouse ? Qt.lighter(root.primaryAccent, 1.1) : root.primaryAccent) : (blurMouse.containsMouse ? root.surface2 : root.base)
                                    border.color: root.enableBlur ? root.primaryAccent : (blurMouse.containsMouse ? root.primaryAccent : root.backCardBorder)
                                    border.width: 1 * s
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.enableBlur ? "Blur: ON" : "Blur: OFF"
                                        color: root.enableBlur ? root.contrastText(root.primaryAccent) : root.text
                                        font.family: dinBold.name
                                        font.pixelSize: 10 * s
                                    }

                                    MouseArea {
                                        id: blurMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.resetIdleTimer();
                                            root.enableBlur = !root.enableBlur;
                                            root.setSetting("enableBlur", root.enableBlur ? "true" : "false");
                                        }
                                    }
                                }

                                // 2. Glow Toggle Pill
                                Rectangle {
                                    width: (parent.width - 6 * s) / 2
                                    height: 25 * s
                                    radius: 6 * s
                                    color: root.enableGlow ? (glowMouse.containsMouse ? Qt.lighter(root.primaryAccent, 1.1) : root.primaryAccent) : (glowMouse.containsMouse ? root.surface2 : root.base)
                                    border.color: root.enableGlow ? root.primaryAccent : (glowMouse.containsMouse ? root.primaryAccent : root.backCardBorder)
                                    border.width: 1 * s
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.enableGlow ? "Glow: ON" : "Glow: OFF"
                                        color: root.enableGlow ? root.contrastText(root.primaryAccent) : root.text
                                        font.family: dinBold.name
                                        font.pixelSize: 10 * s
                                    }

                                    MouseArea {
                                        id: glowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.resetIdleTimer();
                                            root.enableGlow = !root.enableGlow;
                                            root.setSetting("enableGlow", root.enableGlow ? "true" : "false");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------
        // MAIN LOGIN CARD (Sits in front, z: 10)
        // Clean solid matte Catppuccin surface
        // ------------------------------------------------------------
        Rectangle {
            id: mainCard
            z: 10
            width: 280 * s
            height: 242 * s
            radius: 16 * s
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1 * s

            Behavior on color { ColorAnimation { duration: 300 } }
            Behavior on border.color { ColorAnimation { duration: 300 } }

            layer.enabled: root.enableGlow
            layer.effect: DropShadow {
                color: "#bb000000"
                radius: 28
                samples: 16
                horizontalOffset: 0
                verticalOffset: 8 * s
            }

            // Inner Content Area
            Item {
                id: mainCardContent
                anchors.fill: parent
                anchors.margins: 16 * s

                // 1. User Avatar
                Item {
                    id: avatarItem
                    y: 4 * s
                    width: 62 * s
                    height: 62 * s

                    x: {
                        if (root.cardAlignment === "left") return 0;
                        if (root.cardAlignment === "right") return mainCardContent.width - width;
                        return (mainCardContent.width - width) / 2;
                    }
                    Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.color: avatarMouse.containsMouse ? root.primaryAccent : root.surface1
                        border.width: 2 * s
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        id: avatarContent
                        anchors.centerIn: parent
                        width: 56 * s
                        height: 56 * s
                        visible: false

                        Rectangle {
                            anchors.fill: parent
                            color: root.surface0
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

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var name = (userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : "U";
                                return name.charAt(0).toUpperCase();
                            }
                            color: root.primaryAccent
                            font.family: dinBold.name
                            font.pixelSize: 22 * s
                            visible: avatarImg.status !== Image.Ready
                        }
                    }

                    Rectangle {
                        id: avatarMask
                        anchors.centerIn: parent
                        width: 56 * s
                        height: 56 * s
                        radius: width / 2
                        color: "white"
                        visible: false
                    }

                    OpacityMask {
                        anchors.centerIn: parent
                        width: 56 * s
                        height: 56 * s
                        source: avatarContent
                        maskSource: avatarMask
                    }

                    MouseArea {
                        id: avatarMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetIdleTimer();
                            if (typeof userModel !== "undefined" && userModel.rowCount() > 0) {
                                root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                            }
                        }
                    }
                }

                // 2. User Name Label
                Text {
                    id: userNameLabel
                    y: avatarItem.y + avatarItem.height + 6 * s
                    x: 0
                    width: mainCardContent.width
                    text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (userModel.lastUser || "Name"))
                    color: root.text
                    font.family: dinBold.name
                    font.pixelSize: 14 * s
                    horizontalAlignment: {
                        if (root.cardAlignment === "left") return Text.AlignLeft;
                        if (root.cardAlignment === "right") return Text.AlignRight;
                        return Text.AlignHCenter;
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.resetIdleTimer();
                            if (typeof userModel !== "undefined" && userModel.rowCount() > 0) {
                                root.userIndex = (root.userIndex + 1) % userModel.rowCount();
                            }
                        }
                    }
                }

                // 3. Password Input Row (Clean standard bullet masking & Material Symbols visibility toggle)
                Row {
                    id: pwdRow
                    y: userNameLabel.y + userNameLabel.height + 12 * s
                    x: 0
                    width: mainCardContent.width
                    height: 38 * s
                    spacing: 8 * s

                    // Password Input Box
                    Rectangle {
                        id: pwdContainer
                        width: parent.width - eyeBtnFocus.width - 8 * s
                        height: parent.height
                        radius: 10 * s
                        color: root.inputBg
                        border.color: pwd.activeFocus ? root.primaryAccent : root.inputBorder
                        border.width: pwd.activeFocus ? 2 * s : 1 * s
                        property real shakeOffset: 0
                        x: shakeOffset

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ListModel { id: pwdCharModel }

                        function updateCharModel() {
                            while (pwdCharModel.count < pwd.text.length) {
                                pwdCharModel.append({});
                            }
                            while (pwdCharModel.count > pwd.text.length) {
                                pwdCharModel.remove(pwdCharModel.count - 1);
                            }
                            charListView.positionViewAtEnd();
                        }

                        // Real TextInput (handles keyboard events & focus)
                        TextInput {
                            id: pwd
                            anchors.fill: parent
                            color: root.isPasswordVisible ? root.text : "transparent"
                            selectionColor: root.isPasswordVisible ? root.primaryAccent : "transparent"
                            selectedTextColor: root.isPasswordVisible ? root.contrastText(root.primaryAccent) : "transparent"
                            font.family: dinBold.name
                            font.pixelSize: 15 * s
                            font.letterSpacing: root.isPasswordVisible ? 1 * s : 3 * s
                            echoMode: root.isPasswordVisible ? TextInput.Normal : TextInput.Password
                            passwordCharacter: " "
                            cursorVisible: root.isPasswordVisible && pwd.activeFocus
                            cursorDelegate: Rectangle {
                                width: root.isPasswordVisible ? 2 * s : 0
                                height: root.isPasswordVisible ? 16 * s : 0
                                color: root.text
                                visible: root.isPasswordVisible
                            }
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: {
                                if (root.cardAlignment === "left") return TextInput.AlignLeft;
                                if (root.cardAlignment === "right") return TextInput.AlignRight;
                                return TextInput.AlignHCenter;
                            }
                            leftPadding: root.cardAlignment === "left" ? 14 * s : 8 * s
                            rightPadding: root.cardAlignment === "right" ? 14 * s : 8 * s
                            focus: false

                            onTextEdited: {
                                err.text = "";
                                root.resetIdleTimer();
                                pwdContainer.updateCharModel();
                            }
                            onTextChanged: {
                                pwdContainer.updateCharModel();
                            }

                            Keys.onReturnPressed: doLogin()
                            Keys.onEnterPressed: doLogin()
                            KeyNavigation.tab: eyeBtnFocus
                            KeyNavigation.backtab: enterBtnFocus
                        }

                        // Placeholder Text (when empty)
                        Text {
                            anchors.fill: parent
                            visible: pwd.text.length === 0
                            text: "Password..."
                            color: root.overlay0
                            font.family: dinRegular.name
                            font.pixelSize: 13 * s
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: {
                                if (root.cardAlignment === "left") return Text.AlignLeft;
                                if (root.cardAlignment === "right") return Text.AlignRight;
                                return Text.AlignHCenter;
                            }
                            leftPadding: root.cardAlignment === "left" ? 14 * s : 8 * s
                            rightPadding: root.cardAlignment === "right" ? 14 * s : 8 * s
                        }

                        // Custom Animated Rounded Boxes Indicator with PRECISE End-Of-Line Blinking Cursor
                        Item {
                            id: charViewWrapper
                            visible: !root.isPasswordVisible && pwd.text.length > 0
                            height: 14 * s
                            anchors.verticalCenter: parent.verticalCenter

                            readonly property real itemSize: 9 * s
                            readonly property real itemSpacing: 5 * s
                            readonly property real cursorWidth: 2 * s
                            readonly property real cursorGap: 4 * s
                            readonly property real maxAvailableWidth: parent.width - 28 * s
                            readonly property real boxesWidth: pwdCharModel.count * itemSize + Math.max(0, pwdCharModel.count - 1) * itemSpacing
                            readonly property real fullWidth: boxesWidth + (pwd.activeFocus ? (cursorGap + cursorWidth) : 0)
                            width: Math.min(fullWidth, maxAvailableWidth)

                            x: {
                                if (root.cardAlignment === "left") return 14 * s;
                                if (root.cardAlignment === "right") return parent.width - width - 14 * s;
                                return (parent.width - width) / 2;
                            }
                            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Row {
                                anchors.fill: parent
                                spacing: charViewWrapper.cursorGap

                                Item {
                                    width: Math.min(charViewWrapper.boxesWidth, parent.width - (cursorIndicator.visible ? (charViewWrapper.cursorGap + charViewWrapper.cursorWidth) : 0))
                                    height: parent.height
                                    clip: true

                                    ListView {
                                        id: charListView
                                        anchors.fill: parent
                                        orientation: ListView.Horizontal
                                        spacing: charViewWrapper.itemSpacing
                                        interactive: false
                                        model: pwdCharModel

                                        delegate: Rectangle {
                                            readonly property bool isSelected: pwd.selectedText.length > 0 && index >= pwd.selectionStart && index < pwd.selectionEnd
                                            width: charViewWrapper.itemSize
                                            height: charViewWrapper.itemSize
                                            anchors.verticalCenter: parent.verticalCenter
                                            radius: 3 * s
                                            color: isSelected ? root.secondaryAccent : root.primaryAccent
                                            border.color: isSelected ? Qt.lighter(root.secondaryAccent, 1.25) : Qt.lighter(root.primaryAccent, 1.15)
                                            border.width: 1 * s
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }

                                        add: Transition {
                                            ParallelAnimation {
                                                NumberAnimation {
                                                    property: "scale"
                                                    from: 0.1
                                                    to: 1.0
                                                    duration: 220
                                                    easing.type: Easing.OutBack
                                                    easing.overshoot: 2.2
                                                }
                                                NumberAnimation {
                                                    property: "opacity"
                                                    from: 0
                                                    to: 1
                                                    duration: 150
                                                }
                                            }
                                        }

                                        remove: Transition {
                                            ParallelAnimation {
                                                NumberAnimation {
                                                    property: "scale"
                                                    to: 0.1
                                                    duration: 160
                                                    easing.type: Easing.InBack
                                                    easing.overshoot: 2.0
                                                }
                                                NumberAnimation {
                                                    property: "opacity"
                                                    to: 0
                                                    duration: 120
                                                }
                                            }
                                        }

                                        displaced: Transition {
                                            NumberAnimation {
                                                properties: "x,y"
                                                duration: 140
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }
                                }

                                // Blinking Cursor sitting PRECISELY after the last box!
                                Rectangle {
                                    id: cursorIndicator
                                    width: charViewWrapper.cursorWidth
                                    height: 14 * s
                                    radius: 1 * s
                                    color: root.primaryAccent
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: pwd.activeFocus && !root.isPasswordVisible

                                    SequentialAnimation on opacity {
                                        running: cursorIndicator.visible
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.0; duration: 450; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 1.0; duration: 450; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.resetIdleTimer();
                                pwd.forceActiveFocus();
                            }
                        }
                    }

                    // Eye Toggle Button with Material Symbols Icon & Pop Animation
                    Item {
                        id: eyeBtnFocus
                        width: 38 * s
                        height: 38 * s
                        activeFocusOnTab: true
                        KeyNavigation.tab: enterBtnFocus
                        KeyNavigation.backtab: pwd
                        Keys.onReturnPressed: eyeBounceAnim.start()
                        Keys.onSpacePressed: eyeBounceAnim.start()

                        Rectangle {
                            id: eyeBtn
                            anchors.fill: parent
                            radius: 10 * s
                            color: eyeMouse.containsMouse ? root.surface2 : root.surface0
                            border.color: eyeBtnFocus.activeFocus ? root.primaryAccent : root.surface1
                            border.width: eyeBtnFocus.activeFocus ? 2 * s : 1 * s
                            scale: eyeMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                id: eyeIcon
                                anchors.centerIn: parent
                                source: root.isPasswordVisible ? "icons/visibility.svg" : "icons/visibility_off.svg"
                                width: 18 * s
                                height: 18 * s
                                sourceSize.width: width
                                sourceSize.height: height
                                fillMode: Image.PreserveAspectFit
                                layer.enabled: true
                                layer.effect: ColorOverlay { color: root.text }
                            }

                            SequentialAnimation {
                                id: eyeBounceAnim
                                NumberAnimation { target: eyeIcon; property: "scale"; to: 0.7; duration: 90; easing.type: Easing.InQuad }
                                ScriptAction { script: root.isPasswordVisible = !root.isPasswordVisible }
                                NumberAnimation { target: eyeIcon; property: "scale"; to: 1.25; duration: 130; easing.type: Easing.OutBack }
                                NumberAnimation { target: eyeIcon; property: "scale"; to: 1.0; duration: 80; easing.type: Easing.OutQuad }
                            }

                            MouseArea {
                                id: eyeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.resetIdleTimer();
                                    eyeBtnFocus.forceActiveFocus();
                                    eyeBounceAnim.start();
                                }
                            }
                        }
                    }
                }

                // 4. Enter / Login Button (Pill Action CTA)
                Item {
                    id: enterBtnFocus
                    y: pwdRow.y + pwdRow.height + 10 * s
                    x: 0
                    width: mainCardContent.width
                    height: 38 * s
                    activeFocusOnTab: true
                    KeyNavigation.tab: pwd
                    KeyNavigation.backtab: eyeBtnFocus
                    Keys.onReturnPressed: doLogin()
                    Keys.onSpacePressed: doLogin()

                    Rectangle {
                        id: enterBtn
                        anchors.fill: parent
                        radius: 10 * s
                        color: (enterMouse.containsMouse || enterBtnFocus.activeFocus) ? root.btnCtaHover : root.btnCtaBg
                        border.color: Qt.lighter(root.btnCtaBg, 1.15)
                        border.width: 1 * s
                        scale: enterMouse.pressed ? 0.96 : (enterMouse.containsMouse ? 1.02 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        layer.enabled: root.enableGlow
                        layer.effect: DropShadow {
                            color: Qt.rgba(root.primaryAccent.r * 0.5, root.primaryAccent.g * 0.5, root.primaryAccent.b * 0.5, 0.4)
                            radius: 10 * s
                            samples: 16
                            verticalOffset: 3 * s
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Enter"
                            color: root.btnCtaText
                            font.family: dinBold.name
                            font.pixelSize: 14 * s
                            font.letterSpacing: 1 * s
                        }

                        MouseArea {
                            id: enterMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.resetIdleTimer();
                                enterBtnFocus.forceActiveFocus();
                                doLogin();
                            }
                        }
                    }
                }

                // 5. Error text label
                Text {
                    id: err
                    y: enterBtnFocus.y + enterBtnFocus.height + 4 * s
                    x: 0
                    width: mainCardContent.width
                    text: ""
                    color: root.red
                    font.family: dinBold.name
                    font.pixelSize: 11 * s
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ------------------------------------------------------------
        // TAB PULLER HANDLE (z: 15, sits in front of mainCard)
        // Moves in lockstep with backCard's right edge.
        // Being at z: 15 prevents mainCard's drop shadow from falling on it!
        // ------------------------------------------------------------
        Rectangle {
            id: drawerTab
            z: 15
            width: 22 * s
            height: 46 * s
            topRightRadius: 10 * s
            bottomRightRadius: 10 * s
            topLeftRadius: 0
            bottomLeftRadius: 0
            color: drawerTabMouse.containsMouse ? root.surface2 : (root.drawerOpen ? root.primaryAccent : root.surface0)
            border.color: root.surface1
            border.width: 1 * s
            anchors.verticalCenter: mainCard.verticalCenter
            x: backCard.x + backCard.width - 1 * s

            Behavior on color { ColorAnimation { duration: 150 } }

            layer.enabled: root.enableGlow
            layer.effect: DropShadow {
                color: "#77000000"
                radius: 10
                samples: 16
                horizontalOffset: 2 * s
                verticalOffset: 2 * s
            }

            Image {
                id: tabChevron
                anchors.centerIn: parent
                source: "icons/chevron_right.svg"
                width: 13 * s
                height: 13 * s
                sourceSize.width: width
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                rotation: root.drawerOpen ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                layer.enabled: true
                layer.effect: ColorOverlay {
                    color: (root.drawerOpen && !drawerTabMouse.containsMouse) ? root.contrastText(root.primaryAccent) : root.text
                }
            }

            MouseArea {
                id: drawerTabMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.resetIdleTimer();
                    root.drawerOpen = !root.drawerOpen;
                }
            }
        }
    }

    // Shake animation on wrong password
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: pwdContainer; property: "shakeOffset"; to: -10 * s; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: pwdContainer; property: "shakeOffset"; to: 10 * s; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: pwdContainer; property: "shakeOffset"; to: -8 * s; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: pwdContainer; property: "shakeOffset"; to: 8 * s; duration: 60; easing.type: Easing.InOutQuad }
        NumberAnimation { target: pwdContainer; property: "shakeOffset"; to: 0; duration: 60; easing.type: Easing.InOutQuad }
    }

    Timer {
        id: errClearTimer
        interval: 1500
        repeat: false
        onTriggered: err.text = ""
    }

    Timer {
        id: loginDelayTimer
        interval: 500
        repeat: false
        onTriggered: {
            var u = (userHelper.currentItem && userHelper.currentItem.uLogin) ? userHelper.currentItem.uLogin : (typeof userModel !== "undefined" ? userModel.lastUser : "");
            if (typeof sddm !== "undefined") sddm.login(u, pwd.text, root.sessionIndex);
        }
    }

    ParallelAnimation {
        id: loginFadeAnim
        NumberAnimation { target: bgLoader; property: "opacity"; from: 1; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "ui"; from: 1; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "loginUiOpacity"; from: 1; to: 0; duration: 500; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "loginUiScale"; from: 1; to: 0.9; duration: 500; easing.type: Easing.InQuad }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            loginDelayTimer.stop();
            loginFadeAnim.stop();
            bgLoader.opacity = 1;
            root.ui = 1;
            root.clockCentered = false;
            root.loginUiOpacity = 1;
            root.loginUiScale = 1;
            err.text = "ACCESS DENIED";
            errClearTimer.restart();
            pwd.text = "";
            pwd.focus = true;
            shakeAnim.start();
            focusPwdOnce.restart();
            idleTimer.restart();
        }
    }

    function doLogin() {
        if (pwd.text.length === 0) {
            err.text = "PASSWORD REQUIRED";
            errClearTimer.restart();
            pwd.forceActiveFocus();
            shakeAnim.start();
            return;
        }
        loginFadeAnim.start();
        loginDelayTimer.start();
    }

    HoverHandler {
        id: idleHoverTracker
        target: root
        property point lastPos: Qt.point(-1, -1)
        onPointChanged: {
            var p = point.position;
            if (lastPos.x < 0) {
                lastPos = p;
                return;
            }
            var dx = p.x - lastPos.x;
            var dy = p.y - lastPos.y;
            var distSq = dx * dx + dy * dy;
            if (distSq > 16) {
                lastPos = p;
                root.resetIdleTimer();
            }
        }
    }

    TapHandler {
        id: idleTapTracker
        target: root
        acceptedButtons: Qt.AllButtons
        onPressedChanged: if (pressed) root.resetIdleTimer()
    }
}
