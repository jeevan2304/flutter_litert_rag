
import 'flutter_litert_rag_platform_interface.dart';

class FlutterLitertRag {
  Future<String?> getPlatformVersion() {
    return FlutterLitertRagPlatform.instance.getPlatformVersion();
  }
}
