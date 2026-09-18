import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'language_provider.g.dart';

enum AppLanguage {
  indonesian(
    code: 'id',
    name: 'Bahasa Indonesia',
    shortLabel: 'ID',
    flag: '🇮🇩',
  ),
  english(
    code: 'en',
    name: 'English',
    shortLabel: 'EN',
    flag: '🇺🇸',
  ),
  malay(
    code: 'ms',
    name: 'Bahasa Melayu',
    shortLabel: 'MY',
    flag: '🇲🇾',
  );

  final String code;
  final String name;
  final String shortLabel;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.shortLabel,
    required this.flag,
  });
}

@riverpod
class AppLanguageNotifier extends _$AppLanguageNotifier {
  @override
  AppLanguage build() {
    return AppLanguage.indonesian;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }
}
