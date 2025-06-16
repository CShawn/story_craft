import 'dart:io';
import 'package:path/path.dart' as p;
import '../const.dart';

class BookDir {
  String path;
  String name = "";
  String icon = "";
  bool isBook = false;

  BookDir({required this.path}) {
    name = p.basename(path);
    _initBookInfo();
  }

  _initBookInfo() {
    final type = FileSystemEntity.typeSync(path);
    if (type != FileSystemEntityType.directory) {
      return;
    }
    final entities = Directory(path).listSync();
    final hasPageDir = entities.any((e) =>
    e is Directory && p.basename(e.path) == pageDirName);
    if (!hasPageDir) {
      return;
    }
    final pageDir = Directory(p.join(path, pageDirName))
        .listSync()
        .whereType<File>()
        .where((f) {
      final name = p.basenameWithoutExtension(f.path);
      final ext = p.extension(f.path).toLowerCase();
      // 只保留图片文件且无后缀名的文件名是数字
      final isImage = pictureTypes.contains(ext);
      return isImage && int.tryParse(name) != null;
    }).toList();
    if (pageDir.isEmpty) {
      return;
    }
    pageDir.sort((a, b) {
      final aNum = int.parse(p.basenameWithoutExtension(a.path));
      final bNum = int.parse(p.basenameWithoutExtension(b.path));
      return aNum.compareTo(bNum);
    });
    isBook = true;
    icon = pageDir.first.path;
  }
}

class BookDirItem {
  late BookDir bookDir;
  bool isEditing = false;
  BookDirItem(String path) {
    bookDir = BookDir(path: path);
  }

  static clone(BookDirItem item) {
    return BookDirItem(item.bookDir.path);
  }
}