import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageService {
  static final _picker = ImagePicker();
  static final _uuid = const Uuid();

  static Future<String?> pickAndStore({required bool isCamera}) async {
    final XFile? file = await _picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    final dir = await _meterImagesDir();
    final ext = file.name.split('.').last;
    final newPath = '${dir.path}/${_uuid.v4()}.$ext';
    await File(file.path).copy(newPath);
    return newPath;
  }

  /// Overwrite (or create) a single persistent image file per consumer.
  /// Returns the stable file path (meter_<consumerId>.jpg).
  static Future<String?> pickAndStoreForConsumer({
    required int consumerId,
    required bool isCamera,
  }) async {
    final XFile? file = await _picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    final dir = await _meterImagesDir();
    final path = '${dir.path}/meter_$consumerId.jpg';
    final out = File(path);
    if (out.existsSync()) {
      await out.delete();
    }
    await File(file.path).copy(path);
    return path;
  }

  static Future<Directory> _meterImagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/meter_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
