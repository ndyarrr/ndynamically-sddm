import QtQuick
import QtQuick.Window
import QtMultimedia
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import QtQuick.LocalStorage

Item {
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
    
    // Persistent active mode
    property string activeMode: "hybrid"

    Component.onCompleted: {
        activeMode = getSetting("mode", defaultMode);
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
                loadInitialWallpaper()
            }
        }
    }

    property string selectedFile: "bg.mp4" // Fallback video in the theme folder
    property string fileType: "video"      // "video", "gif", or "image"
    property int currentIndex: -1          // Current index of wallpaper in FolderListModel

    function loadInitialWallpaper() {
        if (activeMode === "stay") {
            var saved = getSetting("savedWallpaper", "");
            if (saved !== "" && saved.indexOf("bg.mp4") === -1) {
                // Find if the saved file exists in the folderModel to restore currentIndex
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
                
                if (found) return;
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
            currentIndex = -1;
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
        }
    }

    function changeMode(newMode) {
        if (newMode === "hybrid" || newMode === "video" || newMode === "image" || newMode === "stay") {
            activeMode = newMode;
            setSetting("mode", newMode);
            if (newMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            } else {
                chooseRandomWallpaper();
            }
        }
    }

    function nextWallpaper() {
        if (folderModel.count > 1) {
            currentIndex = (currentIndex + 1) % folderModel.count;
            selectWallpaperIndex(currentIndex);
            if (activeMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            }
        }
    }

    function prevWallpaper() {
        if (folderModel.count > 1) {
            currentIndex = (currentIndex - 1 + folderModel.count) % folderModel.count;
            selectWallpaperIndex(currentIndex);
            if (activeMode === "stay") {
                setSetting("savedWallpaper", selectedFile);
            }
        }
    }

    // 1. VIDEO RENDERER (.mp4)
    MediaPlayer {
        id: mediaplayer
        source: fileType === "video" ? selectedFile : ""
        loops: MediaPlayer.Infinite
        videoOutput: videoOutput
        
        // Auto-play / stop logic to conserve resources when not in use
        onSourceChanged: {
            if (source !== "") {
                mediaplayer.play();
            } else {
                mediaplayer.stop();
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: fileType === "video"
    }

    // 2. GIF RENDERER (.gif)
    AnimatedImage {
        id: animatedImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: fileType === "gif" ? selectedFile : ""
        visible: fileType === "gif"
        playing: visible
    }

    // 3. IMAGE RENDERER (.png, .jpg, .jpeg, .webp)
    Image {
        id: staticImage
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: fileType === "image" ? selectedFile : ""
        visible: fileType === "image"
        asynchronous: true
    }

}
