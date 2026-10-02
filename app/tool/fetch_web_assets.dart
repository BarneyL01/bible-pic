// Downloads the two files drift needs on the web (sqlite3.wasm and
// drift_worker.js) into web/, at the versions pinned in pubspec.lock.
// Run from app/ after `flutter pub get`:  dart run tool/fetch_web_assets.dart
import 'dart:io';

String lockedVersion(String lock, String package) {
  final match = RegExp(
    '^  $package:\\n(?:    .*\\n)*?    version: "([^"]+)"',
    multiLine: true,
  ).firstMatch(lock);
  if (match == null) {
    throw StateError('$package not found in pubspec.lock; run flutter pub get');
  }
  return match.group(1)!;
}

Future<void> download(String url, String target) async {
  final client = HttpClient();
  try {
    var request = await client.getUrl(Uri.parse(url));
    var response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('GET $url -> ${response.statusCode}');
    }
    await response.pipe(File(target).openWrite());
    stdout.writeln('wrote $target');
  } finally {
    client.close();
  }
}

Future<void> main() async {
  final lock = File('pubspec.lock').readAsStringSync();
  final sqlite3 = lockedVersion(lock, 'sqlite3');
  final drift = lockedVersion(lock, 'drift');
  await download(
    'https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-$sqlite3/sqlite3.wasm',
    'web/sqlite3.wasm',
  );
  await download(
    'https://github.com/simolus3/drift/releases/download/drift-$drift/drift_worker.js',
    'web/drift_worker.js',
  );
}
