package com.example.project_anima

import android.content.ContentResolver
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.DisplayCutout
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "project_anima/media_store"
    private val DIMENSIONS_CHANNEL = "project_anima/system_dimensions"
    private var notchObserver: ContentObserver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Automatically determine cutout mode based on notch concealment setting
        applyAdaptiveCutoutMode()

        // Disable automatic system contrast scrims/shadows on status and navigation bars (Android 10+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }

        registerNotchObserver()
    }

    override fun onResume() {
        super.onResume()
        applyAdaptiveCutoutMode()
    }

    override fun onDestroy() {
        unregisterNotchObserver()
        if (isFinishing) {
            val intent = android.content.Intent(this, com.ryanheise.audioservice.AudioService::class.java)
            stopService(intent)
        }
        super.onDestroy()
    }

    /**
     * Detects whether the user or system has enabled "Hide Notch" / "Hide Camera Cutout"
     * on Xiaomi (MIUI/HyperOS), Samsung (One UI), or generic Android letterboxing.
     */
    private fun isNotchHidden(): Boolean {
        // Xiaomi / MIUI / HyperOS check via global settings database
        try {
            val forceBlack = Settings.Global.getInt(contentResolver, "force_black", 0)
            val forceBlackV2 = Settings.Global.getInt(contentResolver, "force_black_v2", 0)
            if (forceBlack == 1 || forceBlackV2 == 1) return true
        } catch (_: Exception) {}

        return false
    }

    /**
     * Sets LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER if notch is hidden so the window
     * begins cleanly below the simulated black bezel without being cut off,
     * or LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES when normal.
     */
    private fun applyAdaptiveCutoutMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val hidden = isNotchHidden()
            val targetMode = if (hidden) {
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
            } else {
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
            if (window.attributes.layoutInDisplayCutoutMode != targetMode) {
                val params = window.attributes
                params.layoutInDisplayCutoutMode = targetMode
                window.attributes = params
            }
        }
    }

    private fun registerNotchObserver() {
        try {
            val uri = Settings.Global.getUriFor("force_black")
            if (uri != null) {
                notchObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
                    override fun onChange(selfChange: Boolean) {
                        super.onChange(selfChange)
                        applyAdaptiveCutoutMode()
                    }
                }
                contentResolver.registerContentObserver(uri, false, notchObserver!!)
            }
        } catch (_: Exception) {}
    }

    private fun unregisterNotchObserver() {
        notchObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
            } catch (_: Exception) {}
            notchObserver = null
        }
    }

    private fun getSystemDimensionsMap(): Map<String, Any?> {
        val density = resources.displayMetrics.density
        val notchHidden = isNotchHidden()

        var statusBarPx = 0
        val statusBarResId = resources.getIdentifier("status_bar_height", "dimen", "android")
        if (statusBarResId > 0) {
            statusBarPx = resources.getDimensionPixelSize(statusBarResId)
        }
        val statusBarDp = if (density > 0) statusBarPx / density else 24.0f

        var navBarPx = 0
        val navBarResId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        if (navBarResId > 0) {
            navBarPx = resources.getDimensionPixelSize(navBarResId)
        }
        val navBarDp = if (density > 0) navBarPx / density else 48.0f

        var physicalWidthPx = 0
        var physicalHeightPx = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val maxMetrics = windowManager.maximumWindowMetrics
            physicalWidthPx = maxMetrics.bounds.width()
            physicalHeightPx = maxMetrics.bounds.height()
        } else {
            val dm = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getRealMetrics(dm)
            physicalWidthPx = dm.widthPixels
            physicalHeightPx = dm.heightPixels
        }
        val physicalWidthDp = if (density > 0) physicalWidthPx / density else 0.0f
        val physicalHeightDp = if (density > 0) physicalHeightPx / density else 0.0f

        var usableWidthPx = 0
        var usableHeightPx = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val currentMetrics = windowManager.currentWindowMetrics
            usableWidthPx = currentMetrics.bounds.width()
            usableHeightPx = currentMetrics.bounds.height()
        } else {
            val dm = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getMetrics(dm)
            usableWidthPx = dm.widthPixels
            usableHeightPx = dm.heightPixels
        }
        val usableWidthDp = if (density > 0) usableWidthPx / density else 0.0f
        val usableHeightDp = if (density > 0) usableHeightPx / density else 0.0f

        var hasCutout = false
        var cutoutTopPx = 0
        var cutoutBottomPx = 0
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val cutout = window.decorView.rootWindowInsets?.displayCutout
            if (cutout != null) {
                hasCutout = true
                cutoutTopPx = cutout.safeInsetTop
                cutoutBottomPx = cutout.safeInsetBottom
            }
        }
        val cutoutTopDp = if (density > 0) cutoutTopPx / density else 0.0f
        val cutoutBottomDp = if (density > 0) cutoutBottomPx / density else 0.0f

        val notchHeightDp = if (cutoutTopDp > 0) cutoutTopDp else statusBarDp

        return mapOf(
            "isNotchHidden" to notchHidden,
            "hasCutout" to hasCutout,
            "notchHeight" to notchHeightDp,
            "statusBarHeight" to statusBarDp,
            "navigationBarHeight" to navBarDp,
            "physicalWidth" to physicalWidthDp,
            "physicalHeight" to physicalHeightDp,
            "usableWidth" to usableWidthDp,
            "usableHeight" to usableHeightDp,
            "cutoutTop" to cutoutTopDp,
            "cutoutBottom" to cutoutBottomDp,
            "density" to density,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "queryAudio") {
                Thread {
                    try {
                        val audioList = queryMediaStoreAudio()
                        runOnUiThread {
                            result.success(audioList)
                        }
                    } catch (e: Exception) {
                        runOnUiThread {
                            result.error("QUERY_ERROR", e.message, null)
                        }
                    }
                }.start()
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DIMENSIONS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSystemDimensions" -> {
                    result.success(getSystemDimensionsMap())
                }
                "setCutoutMode" -> {
                    val mode = call.argument<String>("mode") ?: "auto"
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        val params = window.attributes
                        when (mode) {
                            "never" -> params.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER
                            "shortEdges" -> params.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                            "default" -> params.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT
                            else -> applyAdaptiveCutoutMode()
                        }
                        window.attributes = params
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun queryMediaStoreAudio(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val contentResolver: ContentResolver = applicationContext.contentResolver
        val uri: Uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        val projectionList = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.IS_MUSIC
        )
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            projectionList.add(MediaStore.Audio.AudioColumns.ALBUM_ARTIST)
            projectionList.add(MediaStore.Audio.AudioColumns.DISC_NUMBER)
        }
        val projection = projectionList.toTypedArray()

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor: Cursor? = contentResolver.query(
            uri,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use { c ->
            val idCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val dataCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val albumArtistCol = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                c.getColumnIndex(MediaStore.Audio.AudioColumns.ALBUM_ARTIST)
            } else {
                c.getColumnIndex("album_artist")
            }
            val discCol = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                c.getColumnIndex(MediaStore.Audio.AudioColumns.DISC_NUMBER)
            } else {
                c.getColumnIndex("disc_number")
            }
            val albumIdCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val trackCol = c.getColumnIndex(MediaStore.Audio.Media.TRACK)
            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dateModifiedCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
            val dateAddedCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val sizeCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)

            while (c.moveToNext()) {
                val path = c.getString(dataCol) ?: continue
                val size = c.getLong(sizeCol)
                if (size <= 0) continue

                val rawDuration = c.getLong(durationCol)
                val duration = if (rawDuration > 0) rawDuration else 0L

                val albumArtist = if (albumArtistCol != -1) c.getString(albumArtistCol) else null
                val rawTrack = if (trackCol != -1) c.getInt(trackCol) else 0

                var discNumber: Int? = if (rawTrack >= 1000) rawTrack / 1000 else null
                if (discNumber == null && discCol != -1) {
                    val d = c.getInt(discCol)
                    if (d > 0) discNumber = d
                }
                val trackNumber = if (rawTrack >= 1000) rawTrack % 1000 else if (rawTrack > 0) rawTrack else null

                val songMap = mapOf(
                    "id" to c.getLong(idCol),
                    "path" to path,
                    "title" to (c.getString(titleCol) ?: ""),
                    "artist" to (c.getString(artistCol) ?: "<Desconocido>"),
                    "album" to (c.getString(albumCol) ?: "<Desconocido>"),
                    "albumArtist" to albumArtist,
                    "albumId" to c.getLong(albumIdCol),
                    "trackNumber" to trackNumber,
                    "discNumber" to discNumber,
                    "duration" to duration,
                    "dateModified" to c.getLong(dateModifiedCol),
                    "dateAdded" to c.getLong(dateAddedCol),
                    "size" to c.getLong(sizeCol)
                )
                songs.add(songMap)
            }
        }

        return songs
    }
}
