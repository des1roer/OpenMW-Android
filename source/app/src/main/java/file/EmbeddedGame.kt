package file

import android.content.Context
import android.content.res.AssetManager
import android.os.StatFs
import constants.Constants
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Game data packaged into the APK by tools/stage-embedded-game.sh.
 * It is unpacked once into app-specific storage, where OpenMW reads it like a normal install.
 */
object EmbeddedGame {
    private const val ASSET_DIR = "morrowind"
    private const val MANIFEST = "morrowind.manifest"
    private const val ENCODING = "morrowind.encoding"
    private const val MARKER = ".embedded-game-installed"
    private const val FREE_SPACE_MARGIN = 64L * 1024 * 1024

    class Entry(val size: Long, val path: String)

    fun installDir(): File = File(File(Constants.USER_FILE_STORAGE).parentFile, "Morrowind")

    /** @return the bundled file list, or null when this APK carries no game data */
    fun readManifest(ctx: Context): List<Entry>? = try {
        ctx.assets.open(MANIFEST).bufferedReader().useLines { lines ->
            lines.filter { it.isNotBlank() }.map { line ->
                val tab = line.indexOf('\t')
                Entry(line.substring(0, tab).toLong(), line.substring(tab + 1))
            }.toList()
        }
    } catch (_: IOException) {
        null
    }

    fun encoding(ctx: Context, default: String): String = try {
        ctx.assets.open(ENCODING).bufferedReader().readText().trim().ifEmpty { default }
    } catch (_: IOException) {
        default
    }

    private fun stamp(entries: List<Entry>) = "${entries.size}:${entries.sumOf { it.size }}"

    fun isInstalled(entries: List<Entry>): Boolean = try {
        File(installDir(), MARKER).readText() == stamp(entries)
    } catch (_: IOException) {
        false
    }

    private fun isCurrent(file: File, entry: Entry) = file.isFile && file.length() == entry.size

    /**
     * Copies every bundled file that is missing or has a different size, so an
     * interrupted unpack resumes instead of starting over.
     */
    fun install(ctx: Context, entries: List<Entry>, onProgress: (copied: Long, total: Long) -> Unit) {
        val root = installDir()
        if (!root.isDirectory && !root.mkdirs())
            throw IOException("Cannot create ${root.path}")
        File(root, MARKER).delete()

        val needed = entries.filterNot { isCurrent(File(root, it.path), it) }.sumOf { it.size }
        val available = StatFs(root.path).availableBytes
        if (available < needed + FREE_SPACE_MARGIN) {
            throw IOException(
                "Not enough free space: ${(needed + FREE_SPACE_MARGIN) shr 20} MB needed, " +
                    "${available shr 20} MB available"
            )
        }

        val total = entries.sumOf { it.size }
        val buffer = ByteArray(1 shl 20)
        var copied = 0L
        for (entry in entries) {
            val dst = File(root, entry.path)
            if (!isCurrent(dst, entry)) {
                dst.parentFile?.mkdirs()
                val part = File(dst.parentFile, dst.name + ".part")
                ctx.assets.open("$ASSET_DIR/${entry.path}", AssetManager.ACCESS_STREAMING).use { input ->
                    FileOutputStream(part).use { output ->
                        while (true) {
                            val n = input.read(buffer)
                            if (n < 0) break
                            output.write(buffer, 0, n)
                        }
                    }
                }
                if (!part.renameTo(dst))
                    throw IOException("Cannot write ${dst.path}")
            }
            copied += entry.size
            onProgress(copied, total)
        }

        File(root, MARKER).writeText(stamp(entries))
    }
}
