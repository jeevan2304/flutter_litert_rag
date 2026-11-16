import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_litert_rag_method_channel.dart';

abstract class FlutterLitertRagPlatform extends PlatformInterface {
  /// Constructs a FlutterLitertRagPlatform.
  FlutterLitertRagPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLitertRagPlatform _instance = MethodChannelFlutterLitertRag();

  /// The default instance of [FlutterLitertRagPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLitertRag].
  static FlutterLitertRagPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLitertRagPlatform] when
  /// they register themselves.
  static set instance(FlutterLitertRagPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
