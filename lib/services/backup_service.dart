import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  static const backupFilePrefix = 'billing_backup';

  static Future<File> createBackupArchive() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(await getDatabasesPath(), 'billing.db');
    final imagesDir = Directory(p.join(docs.path, 'meter_images'));
    final billsDir = Directory(p.join(docs.path, 'bills'));

    final encoder = ZipFileEncoder();
    final outFile = File(
      p.join(
        docs.path,
        '${backupFilePrefix}_${DateTime.now().millisecondsSinceEpoch}.zip',
      ),
    );
    if (outFile.existsSync()) outFile.deleteSync();
    encoder.create(outFile.path);
    if (File(dbPath).existsSync()) {
      encoder.addFile(File(dbPath));
    }
    if (imagesDir.existsSync()) {
      encoder.addDirectory(imagesDir, includeDirName: true);
    }
    if (billsDir.existsSync()) {
      encoder.addDirectory(billsDir, includeDirName: true);
    }
    encoder.close();
    return outFile;
  }

  static Future<bool> restoreFromArchive() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (res == null || res.files.single.path == null) return false;
    final zipPath = res.files.single.path!;
    final bytes = File(zipPath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);
    final docs = await getApplicationDocumentsDirectory();
    final dbDir = await getDatabasesPath();

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        List<int> data = file.content as List<int>;
        // Determine target path
        String outPath;
        if (filename.endsWith('billing.db')) {
          outPath = p.join(dbDir, 'billing.db');
        } else if (filename.startsWith('meter_images')) {
          outPath = p.join(docs.path, filename);
        } else if (filename.startsWith('bills')) {
          outPath = p.join(docs.path, filename);
        } else {
          continue; // skip unknown
        }
        final outFile = File(outPath);
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(data, flush: true);
      } else {
        final dir = Directory(p.join(docs.path, filename));
        if (!dir.existsSync()) dir.createSync(recursive: true);
      }
    }
    return true;
  }
}
