package com.example.rage_tap

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Ultra-low-latency SFX player for Rage Tap.
 *
 * ROOT CAUSE of audio-induced frame jank:
 *   audioplayers dispatches SoundPool.play() on Android's main thread via MethodChannel.
 *   Android's Choreographer also runs on the main thread to deliver Flutter vsync callbacks.
 *   SoundPool.play() is a Binder IPC call to AudioFlinger (~2-5 ms on MediaTek).
 *   That 2-5 ms blocks the Choreographer → Flutter misses the vsync → visible hitch on every jump.
 *
 * FIX:
 *   All SoundPool operations run on a dedicated THREAD_PRIORITY_URGENT_AUDIO HandlerThread.
 *   The MethodChannel handler calls result.success(null) IMMEDIATELY (before posting work)
 *   so the Android main thread is never stalled → Choreographer fires on time → smooth 60 fps.
 */
object GameSfx {
    private const val CHANNEL = "com.ragetap/sfx"

    // Dedicated audio thread – never touches the Android main thread.
    private val sfxThread = HandlerThread("rt_sfx", Process.THREAD_PRIORITY_URGENT_AUDIO)
        .also { it.start() }
    private val sfx = Handler(sfxThread.looper)

    private lateinit var pool: SoundPool

    // soundId map – written and read only on sfxThread (no lock needed).
    private val ids = HashMap<String, Int>()
    private var keepAliveStream = 0

    fun register(messenger: BinaryMessenger, context: Context) {
        pool = SoundPool.Builder()
            .setMaxStreams(16)
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .build()

        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            // KEY: return to Dart BEFORE any SoundPool work – main thread stays free.
            result.success(null)

            when (call.method) {
                "load" -> {
                    @Suppress("UNCHECKED_CAST")
                    val sounds = call.argument<List<*>>("sounds") as? List<Map<*, *>>
                        ?: return@setMethodCallHandler
                    sfx.post {
                        sounds.forEach { item ->
                            val name = item["name"] as? String ?: return@forEach
                            val file = item["file"] as? String ?: return@forEach
                            try {
                                context.assets
                                    .openFd("flutter_assets/assets/audio/$file")
                                    .use { fd -> ids[name] = pool.load(fd, 1) }
                            } catch (_: Exception) {
                                try {
                                    val cacheFile = java.io.File(context.cacheDir, "sfx_$file")
                                    if (!cacheFile.exists()) {
                                        context.assets.open("flutter_assets/assets/audio/$file").use { input ->
                                            cacheFile.outputStream().use { output -> input.copyTo(output) }
                                        }
                                    }
                                    ids[name] = pool.load(cacheFile.absolutePath, 1)
                                } catch (_: Exception) {
                                }
                            }
                        }
                    }
                }

                "play" -> {
                    val name = call.argument<String>("name") ?: return@setMethodCallHandler
                    val vol = (call.argument<Any>("volume") as? Number)?.toFloat() ?: 0.85f
                    sfx.post {
                        ids[name]?.let { id -> pool.play(id, vol, vol, 1, 0, 1.0f) }
                    }
                }

                "keepAlive" -> {
                    val enable = call.argument<Boolean>("enable") ?: return@setMethodCallHandler
                    sfx.post {
                        if (enable) {
                            if (keepAliveStream == 0) {
                                // Loop silence at near-zero volume to keep DAC/mixer awake.
                                ids["silence.wav"]?.let { id ->
                                    keepAliveStream = pool.play(id, 0.001f, 0.001f, 0, -1, 1.0f)
                                }
                            }
                        } else {
                            if (keepAliveStream != 0) {
                                pool.stop(keepAliveStream)
                                keepAliveStream = 0
                            }
                        }
                    }
                }
            }
        }
    }
}
