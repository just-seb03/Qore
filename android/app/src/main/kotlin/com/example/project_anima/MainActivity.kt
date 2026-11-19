package com.example.project_anima

import android.content.ContentResolver
import android.database.ContentObserver
import android.database.Cursor
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
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
import java.nio.ByteOrder
import kotlin.math.ceil
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

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
            when (call.method) {
                "queryAudio" -> {
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
                }
                "analyzeBpm" -> {
                    val path = call.argument<String>("path")
                    val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                    if (path.isNullOrBlank()) {
                        result.success(null)
                        return@setMethodCallHandler
                    }
                    Thread {
                        val bpm = try {
                            analyzeAudioBpmNative(path, durationMs)
                        } catch (_: Exception) {
                            null
                        }
                        runOnUiThread {
                            result.success(bpm)
                        }
                    }.start()
                }
                else -> result.notImplemented()
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

    /**
     * Decodes a ~20s representative audio segment via MediaExtractor + MediaCodec into ~10ms RMS energy
     * buckets and computes the track BPM using half-wave onset flux + weighted autocorrelation.
     */
    private fun analyzeAudioBpmNative(path: String, durationMs: Long): Double? {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(path)
            var audioTrackIndex = -1
            var format: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val trackFormat = extractor.getTrackFormat(i)
                val mime = trackFormat.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("audio/")) {
                    audioTrackIndex = i
                    format = trackFormat
                    break
                }
            }
            if (audioTrackIndex == -1 || format == null) return null

            val mime = format.getString(MediaFormat.KEY_MIME) ?: return null
            extractor.selectTrack(audioTrackIndex)

            val formatDurationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
                format.getLong(MediaFormat.KEY_DURATION)
            } else {
                durationMs * 1000L
            }

            // Start ~25% into tracks >= 28s so quiet intros don't dominate tempo detection
            val windowDurationUs = 20_000_000L
            val startUs = if (formatDurationUs > windowDurationUs * 2L) {
                (formatDurationUs * 0.25).toLong()
            } else {
                0L
            }
            if (startUs > 0L) {
                extractor.seekTo(startUs, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
            }

            codec = MediaCodec.createDecoderByType(mime)
            codec.configure(format, null, null, 0)
            codec.start()

            var sampleRate = if (format.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            } else 44100
            var channels = if (format.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            } else 2
            var pcmEncoding = AudioFormat.ENCODING_PCM_16BIT

            val frameRateHz = 100.0
            var samplesPerHop = max(1, (sampleRate / frameRateHz).roundToInt())
            val maxEnergies = 2200
            val energies = DoubleArray(maxEnergies)
            var energyCount = 0

            var accSq = 0.0
            var hopCount = 0
            var inputDone = false
            var outputDone = false
            val bufferInfo = MediaCodec.BufferInfo()
            var iterations = 0

            while (!outputDone && energyCount < maxEnergies && iterations < 4000) {
                iterations++
                if (!inputDone) {
                    val inIdx = codec.dequeueInputBuffer(2500L)
                    if (inIdx >= 0) {
                        val inBuf = codec.getInputBuffer(inIdx)
                        if (inBuf != null) {
                            val sampleSize = extractor.readSampleData(inBuf, 0)
                            if (sampleSize < 0) {
                                codec.queueInputBuffer(inIdx, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputDone = true
                            } else {
                                val pts = extractor.sampleTime
                                codec.queueInputBuffer(inIdx, 0, sampleSize, pts, 0)
                                extractor.advance()
                            }
                        }
                    }
                }

                val outIdx = codec.dequeueOutputBuffer(bufferInfo, 2500L)
                if (outIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    val outFmt = codec.outputFormat
                    if (outFmt.containsKey(MediaFormat.KEY_SAMPLE_RATE)) {
                        sampleRate = outFmt.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        samplesPerHop = max(1, (sampleRate / frameRateHz).roundToInt())
                    }
                    if (outFmt.containsKey(MediaFormat.KEY_CHANNEL_COUNT)) {
                        channels = max(1, outFmt.getInteger(MediaFormat.KEY_CHANNEL_COUNT))
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                        outFmt.containsKey(MediaFormat.KEY_PCM_ENCODING)
                    ) {
                        pcmEncoding = outFmt.getInteger(MediaFormat.KEY_PCM_ENCODING)
                    }
                } else if (outIdx >= 0) {
                    val outBuf = codec.getOutputBuffer(outIdx)
                    if (outBuf != null && bufferInfo.size > 0) {
                        outBuf.position(bufferInfo.offset)
                        outBuf.limit(bufferInfo.offset + bufferInfo.size)

                        when (pcmEncoding) {
                            AudioFormat.ENCODING_PCM_FLOAT -> {
                                val floatBuf = outBuf.order(ByteOrder.LITTLE_ENDIAN).asFloatBuffer()
                                while (floatBuf.remaining() >= channels && energyCount < maxEnergies) {
                                    var mono = 0.0
                                    for (c in 0 until channels) {
                                        mono += floatBuf.get().toDouble()
                                    }
                                    mono /= channels
                                    accSq += mono * mono
                                    hopCount++
                                    if (hopCount >= samplesPerHop) {
                                        energies[energyCount++] = sqrt(accSq / hopCount)
                                        accSq = 0.0
                                        hopCount = 0
                                    }
                                }
                            }
                            AudioFormat.ENCODING_PCM_8BIT -> {
                                while (outBuf.remaining() >= channels && energyCount < maxEnergies) {
                                    var mono = 0.0
                                    for (c in 0 until channels) {
                                        mono += ((outBuf.get().toInt() and 0xFF) - 128) / 128.0
                                    }
                                    mono /= channels
                                    accSq += mono * mono
                                    hopCount++
                                    if (hopCount >= samplesPerHop) {
                                        energies[energyCount++] = sqrt(accSq / hopCount)
                                        accSq = 0.0
                                        hopCount = 0
                                    }
                                }
                            }
                            else -> {
                                val shortBuf = outBuf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                                while (shortBuf.remaining() >= channels && energyCount < maxEnergies) {
                                    var mono = 0.0
                                    for (c in 0 until channels) {
                                        mono += shortBuf.get().toDouble() / 32768.0
                                    }
                                    mono /= channels
                                    accSq += mono * mono
                                    hopCount++
                                    if (hopCount >= samplesPerHop) {
                                        energies[energyCount++] = sqrt(accSq / hopCount)
                                        accSq = 0.0
                                        hopCount = 0
                                    }
                                }
                            }
                        }
                    }
                    codec.releaseOutputBuffer(outIdx, false)
                    if ((bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        outputDone = true
                    }
                }
            }

            return estimateBpmFromEnergy(energies, energyCount, frameRateHz)
        } finally {
            try {
                codec?.stop()
            } catch (_: Exception) {}
            try {
                codec?.release()
            } catch (_: Exception) {}
            try {
                extractor.release()
            } catch (_: Exception) {}
        }
    }

    private fun estimateBpmFromEnergy(
        energies: DoubleArray,
        n: Int,
        frameRateHz: Double
    ): Double? {
        if (n < (frameRateHz * 3).roundToInt()) return null

        val logEnergy = DoubleArray(n)
        var maxLog = 0.0
        for (i in 0 until n) {
            val v = ln(1.0 + 16.0 * kotlin.math.abs(energies[i]))
            logEnergy[i] = v
            if (v > maxLog) maxLog = v
        }
        if (maxLog < 1e-4) return null

        val flux = DoubleArray(n)
        for (i in 1 until n) {
            val diff = logEnergy[i] - logEnergy[i - 1]
            flux[i] = if (diff > 0.0) diff else 0.0
        }

        val halfWin = max(4, (frameRateHz * 0.09).roundToInt())
        val onsets = DoubleArray(n)
        var onsetSum = 0.0
        for (i in 0 until n) {
            val start = max(0, i - halfWin)
            val end = min(n - 1, i + halfWin)
            var localMean = 0.0
            for (k in start..end) {
                localMean += flux[k]
            }
            localMean /= (end - start + 1)
            val v = flux[i] - localMean * 0.9
            if (v > 0.0) {
                onsets[i] = v
                onsetSum += v
            }
        }
        if (onsetSum <= 1e-5) return null

        val mean = onsetSum / n
        for (i in 0 until n) {
            onsets[i] -= mean
        }

        val lagMin = max(2, floor(60.0 * frameRateHz / 205.0).toInt())
        val lagMax = min(n / 2 - 1, ceil(60.0 * frameRateHz / 52.0).toInt())
        if (lagMax <= lagMin + 2) return null

        val acf = DoubleArray(lagMax + 1)
        for (lag in lagMin..lagMax) {
            var corr = 0.0
            var energyA = 0.0
            var energyB = 0.0
            val limit = n - lag
            for (i in 0 until limit) {
                val a = onsets[i]
                val b = onsets[i + lag]
                corr += a * b
                energyA += a * a
                energyB += b * b
            }
            val denom = sqrt(energyA * energyB)
            acf[lag] = if (denom > 1e-9) max(0.0, corr / denom) else 0.0
        }

        val priorBpm = 118.0
        val sigmaOctaves = 0.72
        val ln2 = ln(2.0)
        var bestLag = lagMin
        var bestScore = -1.0

        for (lag in lagMin..lagMax) {
            val candBpm = 60.0 * frameRateHz / lag
            var combined = acf[lag]
            val doubleLag = lag * 2
            if (doubleLag <= lagMax) combined += 0.45 * acf[doubleLag]
            val halfLag = (lag / 2.0).roundToInt()
            if (halfLag >= lagMin) combined += 0.25 * acf[halfLag]

            val logDist = ln(candBpm / priorBpm) / ln2
            val priorWeight = exp(-(logDist * logDist) / (2.0 * sigmaOctaves * sigmaOctaves))
            val score = combined * priorWeight
            if (score > bestScore) {
                bestScore = score
                bestLag = lag
            }
        }

        if (bestScore <= 0.02) return null

        var refinedLag = bestLag.toDouble()
        if (bestLag > lagMin && bestLag < lagMax) {
            val y0 = acf[bestLag - 1]
            val y1 = acf[bestLag]
            val y2 = acf[bestLag + 1]
            val denom = 2.0 * (y0 - 2.0 * y1 + y2)
            if (kotlin.math.abs(denom) > 1e-6) {
                val delta = ((y0 - y2) / denom).coerceIn(-0.5, 0.5)
                refinedLag += delta
            }
        }

        val rawBpm = 60.0 * frameRateHz / refinedLag
        if (rawBpm < 35.0 || rawBpm > 350.0 || rawBpm.isNaN() || rawBpm.isInfinite()) {
            return null
        }
        return (rawBpm * 10.0).roundToInt() / 10.0
    }
}
