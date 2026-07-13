import QtQuick
import QtQuick.Window
import QtMultimedia
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick.LocalStorage

Item {
    id: bgRoot
    readonly property real s: Screen.height / 768
    anchors.fill: parent

    // Database Helper functions
    function getDatabase() {
        return LocalStorage.openDatabaseSync("NdynamicallySddmDB", "1.0", "Database for ndynamically-sddm settings", 100000);
    }

    function initDb() {
        var db = getDatabase();
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, val TEXT)');
        });
    }

    function getSetting(key, defaultVal) {
        initDb();
        var val = defaultVal;
        var db = getDatabase();
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT val FROM settings WHERE key=?', [key]);
            if (rs.rows.length > 0) {
                val = rs.rows.item(0).val;
            }
        });
        return val;
    }

    function setSetting(key, val) {
        initDb();
        var db = getDatabase();
        db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?, ?)', [key, val]);
        });
    }

    // Default mode from theme.conf [General] mode key. Default is "hybrid"
    readonly property string defaultMode: (typeof config !== "undefined" && config.mode) ? config.mode.toLowerCase() : "hybrid"
    
    // Persistent active mode — baca langsung dari DB saat inisialisasi property,
    // supaya nameFilters FolderListModel sudah benar sejak awal dan tidak
    // berubah lagi setelahnya (perubahan nameFilters bisa memicu Ready kedua
    // yang menyebabkan animasi tak diinginkan saat boot)
    property string activeMode: getSetting("mode", defaultMode)

    // Transition effect: fade, wipe, circle, none
    property string activeTransition: getSetting("activeTransition", "fade")

    // Track which direction the current transition is going
    property bool transitionToA: true

    // First wallpaper load flag (skip animation on first load)
    property bool initialLoad: true

    // Guard: pastikan wallpaper awal hanya dipilih SEKALI walau Ready
    // ter-trigger lebih dari sekali saat startup
    property bool initialWallpaperChosen: false
    property bool modeChangePending: false

    signal backgroundReady()
    property bool backgroundReadyFlag: false
    property bool transitionInProgress: false

    Timer {
        id: initialReadyTimer
        interval: 30
        repeat: true
        property int elapsed: 0
        onTriggered: {
            elapsed += interval
            if (isIncomingLayerReady() || elapsed >= 500) {
                stop()
                layerA.opacity = 1
                layerA.z = 2
                layerB.opacity = 0
                layerB.z = 1
                layerAVisible = true
                initialLoad = false
                backgroundReadyFlag = true   // ← tambahan
                backgroundReady()
            }
        }
    }


    Component.onCompleted: {
        // activeMode & activeTransition sudah di-set lewat property initializer di atas
    }

    function cycleTransition() {
        var list = ["fade", "wipe", "circle", "none"];
        var i = list.indexOf(activeTransition);
        activeTransition = list[(i + 1) % list.length];
        setSetting("activeTransition", activeTransition);
    }

    FolderListModel {
        id: folderModel
        // The placeholder @WALLPAPER_DIR@ will be replaced by the installer with the actual path chosen by the user
        folder: "file://@WALLPAPER_DIR@"
        showDirs: false
        
        nameFilters: {
            if (activeMode === "video") {
                return ["*.mp4", "*.gif"];
            } else if (activeMode === "image" || activeMode === "gambar") {
                return ["*.png", "*.jpg", "*.jpeg", "*.webp"];
            } else {
                // "hybrid" or "stay" will load all wallpapers so the user can navigate them
                return ["*.mp4", "*.gif", "*.png", "*.jpg", "*.jpeg", "*.webp"];
            }
        }

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                if (!initialWallpaperChosen) {
                    initialWallpaperChosen = true
                    loadInitialWallpaper()
                } else if (modeChangePending) {
                    modeChangePending = false
                    chooseRandomWallpaper()
                }
            }
        }
    }

    property string selectedFile: "bg.mp4" // Fallback video in the theme folder
    property string fileType: "video"      // "video", "gif", or "image"
    property int currentIndex: -1          // Current index of wallpaper in FolderListModel

    // Dual-layer sources
    property bool layerAVisible: true
    property string sourceA: ""
    property string typeA: ""
    property string sourceB: ""
    property string typeB: ""

    function loadInitialWallpaper() {
        if (activeMode === "stay") {
            var saved = getSetting("savedWallpaper", "");
            if (saved !== "" && saved.indexOf("bg.mp4") === -1) {
                var found = false;
                for (var i = 0; i < folderModel.count; i++) {
                    var fPath = folderModel.get(i, "filePath");
                    if ("file://" + fPath === saved) {
                        currentIndex = i;
                        found = true;
                        break;
                    }
                }
                
                selectedFile = saved;
                // Detect extension
                var ext = saved.split('.').pop().toLowerCase();
                if (ext === "mp4") {
                    fileType = "video";
                } else if (ext === "gif") {
                    fileType = "gif";
                } else {
                    fileType = "image";
                }
                
                switchToWallpaper(selectedFile, fileType);
                return;
            }
        }
        
        // Default / random selection if not in stay mode or saved file not found
        chooseRandomWallpaper();
    }

    function chooseRandomWallpaper() {
        if (folderModel.count > 0) {
            var randomIndex = Math.floor(Math.random() * folderModel.count);
            currentIndex = randomIndex;
            selectWallpaperIndex(currentIndex);
        } else {
            console.log("No matching files found in @WALLPAPER_DIR@ for mode: " + activeMode + ". Falling back to default bg.mp4");
            fileType = "video";
            selectedFile = "bg.mp4";
            sourceA = "bg.mp4";
            typeA = "video";
            layerA.opacity = 0;              // ← ubah dari 1 ke 0
            layerA.z = 2;
            layerB.opacity = 0;
            layerB.z = 1;
            layerAVisible = true;
            currentIndex = -1;
            initialReadyTimer.elapsed = 0;   // ← tambahkan
            initialReadyTimer.start();       // ← tambahkan (ganti baris `initialLoad = false;`)
        }
    }

    function selectWallpaperIndex(index) {
        if (index >= 0 && index < folderModel.count) {
            var filePath = folderModel.get(index, "filePath");
            console.log("Selected wallpaper index " + index + ": " + filePath);
            
            // Detect extension to decide the player element
            var ext = filePath.split('.').pop().toLowerCase();
            if (ext === "mp4") {
                fileType = "video";
            } else if (ext === "gif") {
                fileType = "gif";
            } else {
                fileType = "image";
            }
            
            selectedFile = "file://" + filePath;
            switchToWallpaper(selectedFile, fileType);
        }
    }

    // ============================================================
    // CORE TRANSITION LOGIC
    // ============================================================

    // Timer to wait for incoming layer to be fully loaded/ready before starting animation
    Timer {
        id: transitionTriggerTimer
        interval: 30
        repeat: true
        property int elapsed: 0
        property int readyTicks: 0
        onTriggered: {
            elapsed += interval
            if (isIncomingLayerReady()) {
                readyTicks++
            }
            if (readyTicks >= 2 || elapsed >= 500) {
                stop();
                readyTicks = 0
                startTransitionAnimation();
            }
        }
    }

    function isIncomingLayerReady() {
        if (transitionToA) {
            if (typeA === "image") {
                return staticImageA.status === Image.Ready;
            } else if (typeA === "gif") {
                return animatedImageA.status === Image.Ready;
            } else if (typeA === "video") {
                return playerA.mediaStatus === MediaPlayer.BufferedMedia || 
                       playerA.mediaStatus === MediaPlayer.LoadedMedia || 
                       playerA.position > 0;
            }
        } else {
            if (typeB === "image") {
                return staticImageB.status === Image.Ready;
            } else if (typeB === "gif") {
                return animatedImageB.status === Image.Ready;
            } else if (typeB === "video") {
                return playerB.mediaStatus === MediaPlayer.BufferedMedia || 
                       playerB.mediaStatus === MediaPlayer.LoadedMedia || 
                       playerB.position > 0;
            }
        }
        return true;
    }

    function switchToWallpaper(newFile, newType) {
        // First load: set directly on layer A, no animation
        if (initialLoad) {
            sourceA = newFile;
            typeA = newType;
            layerA.opacity = 0;   // tetap tersembunyi dulu
            layerA.z = 2;
            layerB.opacity = 0;
            layerB.z = 1;
            layerAVisible = true;
            initialReadyTimer.elapsed = 0;
            initialReadyTimer.start();
            return;
        }

        transitionInProgress = true;   // ← tambahkan baris ini

        // Stop any running transitions
        fadeInA.stop();
        fadeInB.stop();
        wipeInA.stop();
        wipeInB.stop();
        circleReveal.stop();
        transitionTriggerTimer.stop();

        // Reset visual state to pre-transition stable state
        resetTransitionState();
        if (layerAVisible) {
            layerA.opacity = 1;
            layerA.z = 2;
            layerB.opacity = 0;
            layerB.z = 1;
        } else {
            layerB.opacity = 1;
            layerB.z = 2;
            layerA.opacity = 0;
            layerA.z = 1;
        }

        // Decide which layer gets the new content
        if (layerAVisible) {
            sourceB = newFile;
            typeB = newType;
            transitionToA = false;
        } else {
            sourceA = newFile;
            typeA = newType;
            transitionToA = true;
        }

        // Prepare the incoming layer state immediately so it's ready but hidden/masked/transparent
        var incoming = transitionToA ? layerA : layerB;
        var outgoing = transitionToA ? layerB : layerA;

        if (activeTransition === "fade") {
            incoming.opacity = 0;
            incoming.z = 2;
            outgoing.opacity = 1;
            outgoing.z = 1;
        } else if (activeTransition === "wipe") {
            incoming.opacity = 1;
            incoming.z = 2;
            outgoing.z = 1;
            incoming.clip = true;
            incoming.width = 0;
        } else if (activeTransition === "circle") {
            incoming.opacity = 1;
            incoming.z = 2;
            outgoing.z = 1;
            if (transitionToA) {
                circleSourceA.hideSource = true;
                circleMask.source = circleSourceA;
            } else {
                circleSourceB.hideSource = true;
                circleMask.source = circleSourceB;
            }
            circleMask.visible = true;
            circleMask.z = 3;
            revealCircle.scale = 0;
        }

        // Start checking for readiness
        transitionTriggerTimer.elapsed = 0;
        transitionTriggerTimer.start();
    }

    function startTransitionAnimation() {
        var incoming = transitionToA ? layerA : layerB;
        var outgoing = transitionToA ? layerB : layerA;

        if (activeTransition === "none") {
            incoming.opacity = 1;
            incoming.z = 2;
            outgoing.opacity = 0;
            outgoing.z = 1;
            finalizeTransition();
            return;
        }

        if (activeTransition === "fade") {
            if (transitionToA) fadeInA.start();
            else fadeInB.start();
        } else if (activeTransition === "wipe") {
            if (transitionToA) wipeInA.start();
            else wipeInB.start();
        } else if (activeTransition === "circle") {
            circleReveal.start();
        }
    }

    function resetTransitionState() {
        layerA.clip = false;
        layerB.clip = false;
        layerA.width = bgRoot.width;
        layerB.width = bgRoot.width;
        circleSourceA.hideSource = false;
        circleSourceB.hideSource = false;
        circleMask.visible = false;
        revealCircle.scale = 0;
    }

    function finalizeTransition() {
        if (transitionToA) {
            layerAVisible = true;
            layerA.opacity = 1;
            layerA.z = 2;
            layerB.opacity = 0;
            layerB.z = 1;
            sourceB = "";
            typeB = "";
        } else {
            layerAVisible = false;
            layerB.opacity = 1;
            layerB.z = 2;
            layerA.opacity = 0;
            layerA.z = 1;
            sourceA = "";
            typeA = "";
        }
        resetTransitionState();
        transitionInProgress = false;   // ← tambahkan baris ini
    }

    function changeMode(newMode) {
        if (newMode === "hybrid" || newMode === "video" || newMode === "image" || newMode === "stay") {
            activeMode = newMode;
            setSetting("mode", newMode);
            if (newMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            } else {
                // Jangan pilih wallpaper langsung di sini — nameFilters baru
                // saja berubah lewat binding activeMode di atas, dan
                // FolderListModel butuh waktu (async) untuk rescan folder
                // dengan filter baru. Tunggu status jadi Ready dulu
                // (lihat onStatusChanged) baru pilih wallpaper acak.
                modeChangePending = true;
            }
        }
    }

    function nextWallpaper() {
        if (transitionInProgress) return;   // ← tambahkan baris ini
        if (folderModel.count > 1) {
            currentIndex = (currentIndex + 1) % folderModel.count;
            selectWallpaperIndex(currentIndex);
            if (activeMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            }
        }
    }

    function prevWallpaper() {
        if (transitionInProgress) return;   // ← tambahkan baris ini
        if (folderModel.count > 1) {
            currentIndex = (currentIndex - 1 + folderModel.count) % folderModel.count;
            selectWallpaperIndex(currentIndex);
            if (activeMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            }
        }
    }

    // ============================================================
    // LAYER A: Video + GIF + Image renderers
    // ============================================================
    Item {
        id: layerA
        x: 0; y: 0
        width: bgRoot.width; height: bgRoot.height
        opacity: 1; z: 2; clip: false
        visible: opacity > 0

        // Inner content stays at full screen size even when parent is clipped (for wipe)
        Item {
            id: contentA
            width: bgRoot.width; height: bgRoot.height

            MediaPlayer {
                id: playerA
                source: typeA === "video" ? sourceA : ""
                loops: MediaPlayer.Infinite
                videoOutput: videoOutA
                audioOutput: AudioOutput { muted: true }
                onSourceChanged: {
                    if (source !== "") { playerA.play(); } else { playerA.stop(); }
                }
            }
            VideoOutput {
                id: videoOutA
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                visible: typeA === "video"
            }
            AnimatedImage {
                id: animatedImageA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: typeA === "gif" ? sourceA : ""
                visible: typeA === "gif"
                playing: visible
            }
            Image {
                id: staticImageA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: typeA === "image" ? sourceA : ""
                visible: typeA === "image"
                asynchronous: true
                sourceSize.width: bgRoot.width      // ← tambahkan
                sourceSize.height: bgRoot.height    // ← tambahkan
            }
        }
    }

    // ============================================================
    // LAYER B: Video + GIF + Image renderers
    // ============================================================
    Item {
        id: layerB
        x: 0; y: 0
        width: bgRoot.width; height: bgRoot.height
        opacity: 0; z: 1; clip: false
        visible: opacity > 0

        // Inner content stays at full screen size even when parent is clipped (for wipe)
        Item {
            id: contentB
            width: bgRoot.width; height: bgRoot.height

            MediaPlayer {
                id: playerB
                source: typeB === "video" ? sourceB : ""
                loops: MediaPlayer.Infinite
                videoOutput: videoOutB
                audioOutput: AudioOutput { muted: true }
                onSourceChanged: {
                    if (source !== "") { playerB.play(); } else { playerB.stop(); }
                }
            }
            VideoOutput {
                id: videoOutB
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                visible: typeB === "video"
            }
            AnimatedImage {
                id: animatedImageB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: typeB === "gif" ? sourceB : ""
                visible: typeB === "gif"
                playing: visible
            }
            Image {
                id: staticImageB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: typeB === "image" ? sourceB : ""
                visible: typeB === "image"
                asynchronous: true
                sourceSize.width: bgRoot.width      // ← tambahkan
                sourceSize.height: bgRoot.height
            }
        }
    }

    // ============================================================
    // CIRCLE REVEAL COMPONENTS
    // ============================================================
    ShaderEffectSource {
        id: circleSourceA
        sourceItem: layerA
        hideSource: false
        live: circleMask.visible
    }

    ShaderEffectSource {
        id: circleSourceB
        sourceItem: layerB
        hideSource: false
        live: circleMask.visible
    }

    // Circle mask container to prevent stretching (keeps mask source at full aspect ratio)
    Item {
        id: maskContainer
        anchors.fill: parent
        visible: false

        Rectangle {
            id: revealCircle
            width: Math.max(bgRoot.width, bgRoot.height) * 1.5
            height: width
            radius: width / 2
            color: "white"
            anchors.centerIn: parent
            scale: 0
        }
    }

    // OpacityMask renders the incoming layer through the expanding circle
    OpacityMask {
        id: circleMask
        anchors.fill: parent
        source: circleSourceA
        maskSource: maskContainer
        visible: false
        z: 3
    }

    // ============================================================
    // ANIMATIONS (all use SequentialAnimation + ScriptAction)
    // ============================================================

    // --- FADE ---
    SequentialAnimation {
        id: fadeInB
        ParallelAnimation {
            NumberAnimation { target: layerB; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { target: layerA; property: "opacity"; from: 1; to: 0; duration: 600; easing.type: Easing.InOutQuad }
        }
        ScriptAction { script: finalizeTransition() }
    }

    SequentialAnimation {
        id: fadeInA
        ParallelAnimation {
            NumberAnimation { target: layerA; property: "opacity"; from: 0; to: 1; duration: 600; easing.type: Easing.InOutQuad }
            NumberAnimation { target: layerB; property: "opacity"; from: 1; to: 0; duration: 600; easing.type: Easing.InOutQuad }
        }
        ScriptAction { script: finalizeTransition() }
    }

    // --- WIPE (left-to-right) ---
    SequentialAnimation {
        id: wipeInB
        NumberAnimation { target: layerB; property: "width"; from: 0; to: bgRoot.width; duration: 700; easing.type: Easing.OutCubic }
        ScriptAction { script: finalizeTransition() }
    }

    SequentialAnimation {
        id: wipeInA
        NumberAnimation { target: layerA; property: "width"; from: 0; to: bgRoot.width; duration: 700; easing.type: Easing.OutCubic }
        ScriptAction { script: finalizeTransition() }
    }

    // --- CIRCLE REVEAL (center outward) ---
    SequentialAnimation {
        id: circleReveal
        NumberAnimation { target: revealCircle; property: "scale"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
        ScriptAction { script: finalizeTransition() }
    }

}
