import java.nio.file.Files
// import java.nio.file.Path
import java.nio.file.Paths

class FileUtils {
    def static isSymbolicLink(String filePath) {
        return Files.isSymbolicLink(Paths.get(filePath))
    }
}
