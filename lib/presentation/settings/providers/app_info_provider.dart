import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides PackageInfo fetched asynchronously from the native platform
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Formatted application version display string (e.g. 'v1.0.3')
final appVersionStringProvider = Provider<String>((ref) {
  final packageInfoAsync = ref.watch(packageInfoProvider);
  return packageInfoAsync.when(
    data: (info) => 'v${info.version}',
    loading: () => 'v1.1.4',
    error: (err, stack) => 'v1.1.4',
  );
});
