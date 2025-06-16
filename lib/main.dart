import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'l10n/app_localizations.dart';
import 'package:story_craft/bean/book_dir.dart';
import 'book.dart';
import 'utils/sp_util.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'const.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 获取单例实例
  SpUtil spUtil = SpUtil();
  await spUtil.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange,
          secondary: Colors.green.shade800,
          surface: Colors.yellow.shade100,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.yellow.shade100,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
        color: Colors.deepPurple,
          ),
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isEditing = false;
  int _level = 0;
  String _currentPath = "";
  List<BookDirItem>? _gridItems = [];
  List<BookDirItem>? _backupData = [];

  final SpUtil _spUtil = SpUtil();
  @override
  void initState() {
    super.initState();
    _loadBookShelf();
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isPortrait ? kToolbarHeight : 38,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _level == 0
        ? _isEditing ? IconButton(
            onPressed: _cancelEdit,
            icon: Icon(Icons.close, color: Colors.white,),
          ) : null/*IconButton(
            onPressed: _editBookShelf,
            icon: Icon(
              Icons.edit, 
              color: Colors.white,
            )
          ) */
        : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white,),
            onPressed: _back,
          ),
        title: Text(AppLocalizations.of(context)!.title, style: const TextStyle(color: Colors.white)),
        actions: _level == 0 ? [
          if (_isEditing)
            IconButton(
              onPressed: _editBookShelf,
              icon: Icon(
                Icons.check, 
                color: Colors.white,
              ),
            ),
        ] : [],
      ),
      body: Center(
        child: _gridItems == null ? CircularProgressIndicator() : _gridItems!.isEmpty ? Text(AppLocalizations.of(context)!.empty) : _bookShelf()
      ),
      floatingActionButton: Visibility(
        visible: _isEditing,
        child: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          onPressed: _chooseBookDir,
          child: const Icon(Icons.add, color: Colors.white,),
        ),
      ),
    );
  }

  // 加载书架
  _loadBookShelf() async {
    List<String>? dirs = _spUtil.getStringList(keyBookDir);
    if (dirs?.isNotEmpty != true) {
      String defaultDir = await _createExternalSubDir(bookDirName);
      dirs = Directory(defaultDir)
        .listSync()
        .whereType<Directory>()
        .map((dir) => dir.path)
        .toList();
    }
    final bookDirs = dirs
      ?.where((dir) => Directory(dir).existsSync())
      .map((dir) => BookDirItem(dir))
      .toList()??[];
    bookDirs.sort(_sortBookShelf);
    setState(() {
      _gridItems = bookDirs;
    });
  }
  
  Future<String> _createExternalSubDir(String subDirName) async {
    final baseDir = await getExternalStorageDirectory(); // 外部专属目录
    final targetDir = Directory(path.join(baseDir!.path, subDirName));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir.path;
  }

  // 返回上一级目录
  _back() {
    if (_level == 0) {
      return;
    }
    setState(() {
      _level--;
      _currentPath = _getParentPath(_currentPath);
      if (_level != 0 && Directory(_currentPath).existsSync()) {
        _gridItems = Directory(_currentPath)
            .listSync()
            .whereType<Directory>()
            .where((dir) => dir.existsSync() && !path.basename(dir.path).startsWith("."))
            .map((f) => BookDirItem(f.path))
            .toList();
        _gridItems?.sort(_sortBookShelf);
      }
    });
    if (_level == 0 || !Directory(_currentPath).existsSync()) {
      setState(() {
        _level = 0;
        _currentPath = "";
      });
      _loadBookShelf();
    }
  }

  // 获取上一级目录路径
  String _getParentPath(String currentPath) {
    List<String> parts = currentPath.split(path.separator);
    if (parts.length > 1) {
      currentPath = path.joinAll(parts.sublist(0, parts.length - 1));
    }
    return currentPath;
  }

  // 书架列表视图
  Widget _bookShelf() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: _gridItems!.length,
      itemBuilder: (context, index) {
        final item = _gridItems![index];
        return GestureDetector(
          onTap: () => _clickBookItem(context, item, index),
          child: GridTile(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    !item.bookDir.isBook ?
                      Icon(Icons.folder, color: Theme.of(context).colorScheme.inversePrimary, size: 100) :
                      Image.file(
                        File(item.bookDir.icon),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    if (_isEditing)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _deleteBook(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  item.bookDir.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 点击书籍或目录
  _clickBookItem(BuildContext context, BookDirItem item, int index) {
    if (_isEditing) {
      // 编辑状态下，点击书籍或目录不做任何操作
      return;
    }
    if (item.bookDir.isBook) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookPageView(bookDir: item.bookDir.path, index: index, bookList: _gridItems),
        ),
      );
      return;
    }
    // 非书籍目录，加载该目录下所有文件路径
    final dir = Directory(item.bookDir.path).listSync()
        .whereType<Directory>()
        .where((dir) => dir.existsSync() && !path.basename(dir.path).startsWith("."))
        .map((f) => BookDirItem(f.path))
        .toList();
    dir.sort(_sortBookShelf);
    setState(() {
      _level++;
      _currentPath = item.bookDir.path;
      _gridItems = dir;
    });
  }

  // 选择书籍或目录
  Future<void> _chooseBookDir() async {
    String? selectedDir = await FilePicker.platform.getDirectoryPath();
    if (!mounted) return;
    if (selectedDir == null) {
      return;
    }
    // 判断是否已存在
    bool exists = _gridItems!.any((item) => item.bookDir.path == selectedDir);
    if (exists) {
      return;
    }
    setState(() {
      _gridItems!.add(BookDirItem(selectedDir));
    });
  }

  // 编辑书架
  void _editBookShelf() {
    if (_isEditing) {
      List<String> paths = _gridItems!.map((item) => item.bookDir.path).toList();
      _spUtil.setStringList(keyBookDir, paths);
    } else {
      _backupData = _gridItems!.map((item) => BookDirItem.clone(item)).toList().cast<BookDirItem>();
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // 取消编辑
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _gridItems = _backupData;
    });
  }

  // 删除书籍
  void _deleteBook(int index) {
    setState(() {
      _gridItems!.removeAt(index);
    });
  }

  int _sortBookShelf(BookDirItem a, BookDirItem b) {
    final reg = RegExp(r'^(\d+)(.*)$');
    final aMatch = reg.firstMatch(a.bookDir.name);
    final bMatch = reg.firstMatch(b.bookDir.name);

    if (aMatch != null && bMatch != null) {
      final aNum = int.parse(aMatch.group(1)!);
      final bNum = int.parse(bMatch.group(1)!);
      if (aNum != bNum) {
        return aNum.compareTo(bNum);
      }
      return aMatch.group(2)!.compareTo(bMatch.group(2)!);
    } else if (aMatch != null) {
      // a is number, b is not
      return -1;
    } else if (bMatch != null) {
      // b is number, a is not
      return 1;
    } else {
      return a.bookDir.name.compareTo(b.bookDir.name);
    }
  }
}
