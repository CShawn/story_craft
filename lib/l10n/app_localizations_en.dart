// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Story Craft';

  @override
  String get empty => 'There is nothing here.';

  @override
  String get back => 'Back';

  @override
  String get manual => 'Manual';

  @override
  String get subtitle => 'Subtitle';

  @override
  String get singlePlay => 'Single';

  @override
  String get singleLoop => 'Single Loop';

  @override
  String get listPlay => 'List';

  @override
  String get listLoop => 'List Loop';
}
