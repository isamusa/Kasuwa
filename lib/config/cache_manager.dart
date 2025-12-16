import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CustomCacheManager {
  static const key = 'customCacheKey';

  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7), // How long images are cached
      maxNrOfCacheObjects: 200, // Max number of images to cache
      repo: JsonCacheInfoRepository(databaseName: key),
      fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}
