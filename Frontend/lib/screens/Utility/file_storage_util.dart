import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Utility class for handling file storage operations
class FileStorageUtil {
  static const Uuid _uuid = Uuid();

  /// Saves a file to local storage and returns the local path
  /// Takes a File object and saves it with a unique name
  /// Returns the file path where the file was saved
  static Future<String> saveFile(File file) async {
    // Get app's document directory for file storage
    final directory = await getApplicationDocumentsDirectory();

    // Extract file extension and create unique filename
    final fileExtension = file.path.split('.').last;
    final fileName = '${_uuid.v4()}.$fileExtension';

    // Copy the file to the app's documents directory with unique name
    final savedFile = await file.copy('${directory.path}/$fileName');
    return savedFile.path;
  }

  /// Generates a local URL for accessing the file
  /// Takes a file path and returns a URL with file:// protocol
  static String generateFileUrl(String filePath) {
    return 'file://$filePath';
  }

  /// Check if file is of allowed type
  /// Validates if the file extension is in the allowed formats list
  /// Returns true if the file is of an allowed type, false otherwise
  static bool isAllowedFileType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    // List of allowed file extensions
    final allowedTypes = [
      // Image formats
      'jpg', 'jpeg', 'png', 'svg',
      // Document formats
      'doc', 'docx', 'txt', 'csv', 'pdf',
    ];

    return allowedTypes.contains(extension);
  }

  /// Get file type category (image or document)
  /// Takes a file path and returns the type category based on extension
  static String getFileType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;

    // Check if the extension belongs to image formats
    if (['jpg', 'jpeg', 'png', 'svg'].contains(extension)) {
      return 'image';
    } else {
      return 'document';
    }
  }

  /// Get MIME type of a file
  static String? getMimeType(String filePath) {
    return lookupMimeType(filePath);
  }

  /// Check if file is an image
  static bool isImage(String filePath) {
    final mimeType = getMimeType(filePath);
    return mimeType != null && mimeType.startsWith('image/');
  }
}
