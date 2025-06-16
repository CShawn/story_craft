import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:story_craft/bean/book_dir.dart';
import 'package:story_craft/l10n/app_localizations.dart';
import 'const.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'utils/sp_util.dart';
import 'package:flutter/services.dart';

class BookPageView extends StatefulWidget {
  final String bookDir;
  final int index;
  final List<BookDirItem>? bookList;
  final PlayMode playMode;
  const BookPageView({super.key, required this.bookDir, required this.index, this.bookList, this.playMode = PlayMode.manual});

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView> {
  List<_PageData> _pages = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Timer? _delayedAudioTask;
  bool _drawerOpen = false;
  bool _subtitleSwitch = true; // 字幕开关
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  Timer? _drawerTimer;
  PlayMode _playMode = PlayMode.manual;
  final PageController _pageController = PageController();
  final sp = SpUtil();

  // 获取模式对应的图标和文案
  IconData get _playModeIcon {
    switch (_playMode) {
      case PlayMode.manual: return Icons.touch_app;
      case PlayMode.single: return Icons.ondemand_video;
      case PlayMode.singleLoop: return Icons.repeat_one;
      case PlayMode.list: return Icons.list;
      case PlayMode.listLoop: return Icons.repeat;
    }
  }
  String get _playModeLabel {
    switch (_playMode) {
      case PlayMode.manual: return AppLocalizations.of(context)!.manual;
      case PlayMode.single: return AppLocalizations.of(context)!.singlePlay;
      case PlayMode.singleLoop: return AppLocalizations.of(context)!.singleLoop;
      case PlayMode.list: return AppLocalizations.of(context)!.listPlay;
      case PlayMode.listLoop: return AppLocalizations.of(context)!.listLoop;
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    // _restoreState();
    _playMode = widget.playMode;
    _loadPages();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _drawerTimer?.cancel();
    _delayedAudioTask?.cancel();
    _autoPlayTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final page = _pages[index];
            return GestureDetector(
              onTap: () {
                if (!_isPlaying) {
                  _playAudio(page.audioPath);
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: Image.file(File(page.imagePath), fit: BoxFit.contain),
                  ),
                  if (page.text?.isNotEmpty == true && _subtitleSwitch)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.4 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            page.text!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 40,
                              color: Colors.black,
                              decoration: TextDecoration.none,
                              fontWeight: FontWeight.normal,
                              shadows: [
                                Shadow(
                                  // white outline
                                  offset: Offset(0, 0),
                                  blurRadius: 4,
                                  color: Colors.white,
                                ),
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 0,
                                  color: Colors.white,
                                ),
                                Shadow(
                                  offset: Offset(-1, -1),
                                  blurRadius: 0,
                                  color: Colors.white,
                                ),
                                Shadow(
                                  offset: Offset(1, -1),
                                  blurRadius: 0,
                                  color: Colors.white,
                                ),
                                Shadow(
                                  offset: Offset(-1, 1),
                                  blurRadius: 0,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              )
            );
          },
        ),
        // 点击抽屉外区域收回
        if (_drawerOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _drawerOpen = false;
                });
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        // 顶部抽屉
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
          top: 0,
          left: 0,
          right: 0,
          height: _drawerOpen ? 80 : 40,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              width: _drawerOpen ? 260 : 64,
              margin: EdgeInsets.symmetric(
                horizontal: (MediaQuery.of(context).size.width - (_drawerOpen ? 260 : 64)) / 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha((0.4 * 255).toInt()),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(0),
                  topRight: const Radius.circular(0),
                  bottomLeft: Radius.circular(_drawerOpen ? 16 : 24),
                  bottomRight: Radius.circular(_drawerOpen ? 16 : 24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _drawerOpen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DrawerItem(
                          icon: Icons.arrow_back,
                          label: AppLocalizations.of(context)!.back,
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        _DrawerItem(
                          icon: _subtitleSwitch ? Icons.subtitles : Icons.subtitles_off,
                          label: AppLocalizations.of(context)!.subtitle,
                          onTap: _toggleSubtitle,
                        ),
                        _DrawerItem(
                          icon: _playModeIcon,
                          label: _playModeLabel,
                          onTap: _switchPlayMode,
                        ),
                      ],
                    )
                  : InkWell(
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(0),
                        topRight: const Radius.circular(0),
                        bottomLeft: const Radius.circular(24),
                        bottomRight: const Radius.circular(24),
                      ),
                      onTap: () {
                        setState(() {
                          _drawerOpen = true;
                        });
                        _delayCloseDrawer();
                      },
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ]
    );
  }

  // 恢复之前的状态
  Future<void> _restoreState() async {
    // 恢复播放模式
    int? modeIndex = sp.getInt(keyPlayMode);
    if (modeIndex != null && modeIndex >= 0 && modeIndex < PlayMode.values.length) {
      _playMode = PlayMode.values[modeIndex];
    } else {
      _playMode = PlayMode.manual;
    }
    // 恢复字幕开关
    bool? subtitle = sp.getBool(keySubtitleSwitch);
    _subtitleSwitch = subtitle ?? true;
  }

  // 加载页面数据
  Future<void> _loadPages() async {
    // 1. 读取图片文件
    final pageDir = Directory(p.join(widget.bookDir, pageDirName));
    final imageFiles = await pageDir
        .list()
        .where((entity) =>
            entity is File &&
            RegExp(r'^\d+$').hasMatch(p.basenameWithoutExtension(entity.path)))
        .cast<File>()
        .toList();

    // 2. 排序
    imageFiles.sort((a, b) {
      final aNum = int.parse(p.basenameWithoutExtension(a.path));
      final bNum = int.parse(p.basenameWithoutExtension(b.path));
      return aNum.compareTo(bNum);
    });

    // 3. 读取文本内容
    final textFile = File(p.join(widget.bookDir, textFileName));
    Map<int, String> textMap = {};
    if (await textFile.exists()) {
      final lines = await textFile.readAsLines();
      for (var line in lines) {
        final match = RegExp(r'^(\d+)#(.*)$').firstMatch(line);
        if (match != null) {
          textMap[int.parse(match.group(1)!)] = match.group(2) ?? '';
        }
      }
    }

    // 4. 读取音频
    Map<int, String> audioMap = {};
    final audioDir = Directory(p.join(widget.bookDir, audioDirName));
    if (audioDir.existsSync()) {
      final audioFiles = await audioDir
          .list()
          .where((entity) =>
              entity is File &&
              RegExp(r'^\d+$').hasMatch(p.basenameWithoutExtension(entity.path)))
          .cast<File>()
          .toList();
      for (var file in audioFiles) {
        audioMap[int.parse(p.basenameWithoutExtension(file.path))] = file.path;
      }
    }

    // 5. 组装页面数据
    final loadedPages = imageFiles.map((file) {
      final num = int.parse(p.basenameWithoutExtension(file.path));
      return _PageData(
        imagePath: file.path,
        audioPath: audioMap[num],
        text: textMap[num] ?? '',
      );
    }).toList();

    setState(() {
      _pages = loadedPages;
    });

    _onPageChanged(0);
  }

  // 字幕开关
  void _toggleSubtitle() {
    setState(() {
      _subtitleSwitch = !_subtitleSwitch;
    });
    // sp.setBool(keySubtitleSwitch, _subtitleSwitch);
    _delayCloseDrawer();
  }

  Future<void> _playAudio(String? path) async {
    if (path == null) return;
    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });

      // 等待播放完成
      await _audioPlayer.playerStateStream
          .firstWhere((state) => state.processingState == ProcessingState.completed);

      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      //
    }
  }

  // 播放模式切换
  void _switchPlayMode() {
    _autoPlayTimer?.cancel();
    setState(() {
      _playMode = PlayMode.values[(_playMode.index + 1) % PlayMode.values.length];
    });
    // sp.setInt(keyPlayMode, _playMode.index);
    _delayCloseDrawer();

    if (_playMode == PlayMode.manual) {
      return;
    }
    if (_isPlaying) {
      // 如果正在播放，什么都不做，等播放完后自动翻页
      return;
    }
    _autoPlayTimer = Timer(const Duration(seconds: 1), () {
      _handleAutoPlayNext(_currentPage);
    });
  }

  void _onPageChanged(int index) async {
    _autoPlayTimer?.cancel();
    _delayedAudioTask?.cancel();
    _currentPage = index;
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    }

    final page = _pages[index];
    if (page.audioPath != null) {
      // 有音频，延时800ms播放
      _delayedAudioTask = Timer(const Duration(milliseconds: 800), () async {
        if (!mounted) return;
        await _playAudio(page.audioPath);
        // 自动模式下，音频播放完后延时1s切下一页
        if (_playMode != PlayMode.manual) {
          _autoPlayTimer = Timer(const Duration(seconds: 1), () {
            _handleAutoPlayNext(index);
          });
        }
      });
    } else {
      // 无音频，自动模式下延时5s切下一页
      if (_playMode != PlayMode.manual) {
        _autoPlayTimer = Timer(const Duration(seconds: 5), () {
          _handleAutoPlayNext(index);
        });
      }
    }
  }

  void _handleAutoPlayNext(int pageIndex) {
    if (_playMode == PlayMode.manual) return;
    final isLastPage = pageIndex >= _pages.length - 1;
    if (!_pageController.hasClients) return;
    switch (_playMode) {
      case PlayMode.manual:
        break;
      case PlayMode.single:
        if (!isLastPage) {
          _pageController.animateToPage(
            pageIndex + 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.ease,
          );
        }
        break;
      case PlayMode.singleLoop:
        if (!isLastPage) {
          _pageController.animateToPage(
            pageIndex + 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.ease,
          );
        } else {
          _pageController.jumpToPage(0);
        }
        break;
      case PlayMode.list:
      case PlayMode.listLoop:
        if (!isLastPage) {
          _pageController.animateToPage(
            pageIndex + 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.ease,
          );
        } else {
          _autoPlayNextBook();
        }
        break;
    }
  }

  void _autoPlayNextBook() {
    if (widget.bookList == null || widget.bookList!.isEmpty) {
      _autoPlayTimer?.cancel();
      return;
    }
    int currentBookIndex = widget.index;
    int nextBookIndex = currentBookIndex + 1;
    // 找下一个 isBook==true 的 BookDirItem
    while (nextBookIndex < widget.bookList!.length && !widget.bookList![nextBookIndex].bookDir.isBook) {
      nextBookIndex++;
    }
    if (nextBookIndex < widget.bookList!.length) {
      _autoPlayTimer?.cancel();
      // 跳到下一个书
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => BookPageView(
            bookDir: widget.bookList![nextBookIndex].bookDir.path,
            index: nextBookIndex,
            bookList: widget.bookList,
            playMode: _playMode,
          ),
        ),
      );
    } else if (_playMode == PlayMode.listLoop) {
      _autoPlayTimer?.cancel();
      // 列表循环，从头开始
      int firstBookIndex = widget.bookList!.indexWhere((item) => item.bookDir.isBook);
      if (firstBookIndex != -1) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BookPageView(
              bookDir: widget.bookList![firstBookIndex].bookDir.path,
              index: firstBookIndex,
              bookList: widget.bookList,
              playMode: _playMode,
            ),
          ),
        );
      }
    } else {
      // 列表播放结束
      _autoPlayTimer?.cancel();
    }
  }

  // 延迟关闭抽屉
  _delayCloseDrawer() {
    _drawerTimer?.cancel();
    _drawerTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _drawerOpen = false;
      });
    });
  }
}

// 页面数据模型
class _PageData {
  final String imagePath;
  final String? audioPath;
  final String? text;
  _PageData({required this.imagePath, this.audioPath, this.text});
}

// 抽屉条目组件
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    );
  }
}

enum PlayMode {
  manual,
  single,
  singleLoop,
  list,
  listLoop,
}