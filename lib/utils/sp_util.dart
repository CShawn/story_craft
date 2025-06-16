import 'package:shared_preferences/shared_preferences.dart';

class SpUtil {
  // 创建一个单例模式，避免重复初始化
  static final SpUtil _instance = SpUtil._internal();
  factory SpUtil() => _instance;
  SpUtil._internal();

  // 存储 SharedPreferences 实例
  late SharedPreferences _prefs;

  // 初始化 SharedPreferences 实例，通常在应用启动时调用
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // 存储 String 类型数据
  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  // 获取 String 类型数据
  String? getString(String key) {
    return _prefs.getString(key);
  }

  // 存储 int 类型数据
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  // 获取 int 类型数据
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  // 存储 double 类型数据
  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  // 获取 double 类型数据
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  // 存储 bool 类型数据
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  // 获取 bool 类型数据
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  // 存储 String 列表数据
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  // 获取 String 列表数据
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // 检查某个键是否存在于 SharedPreferences 中
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // 删除某个键值对
  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  // 清除所有数据
  Future<bool> clear() {
    return _prefs.clear();
  }
}