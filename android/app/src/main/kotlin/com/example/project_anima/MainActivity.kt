package com.example.project_anima

import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "project_anima/media_store"

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
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.IS_MUSIC
        )
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
            projectionList.add(MediaStore.Audio.AudioColumns.ALBUM_ARTIST)
        }
        val projection = projectionList.toTypedArray()

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} >= 30000"
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
            val albumIdCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val dateModifiedCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
            val dateAddedCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val sizeCol = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)

            while (c.moveToNext()) {
                val path = c.getString(dataCol) ?: continue
                val duration = c.getLong(durationCol)
                if (duration < 30000) continue

                val albumArtist = if (albumArtistCol != -1) c.getString(albumArtistCol) else null

                val songMap = mapOf(
                    "id" to c.getLong(idCol),
                    "path" to path,
                    "title" to (c.getString(titleCol) ?: ""),
                    "artist" to (c.getString(artistCol) ?: "<Desconocido>"),
                    "album" to (c.getString(albumCol) ?: "<Desconocido>"),
                    "albumArtist" to albumArtist,
                    "albumId" to c.getLong(albumIdCol),
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
