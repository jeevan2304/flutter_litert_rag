import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_litert_rag/flutter_litert_rag.dart';
import 'package:flutter_litert_rag/flutter_litert_rag_platform_interface.dart';
import 'package:flutter_litert_rag/flutter_litert_rag_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLitertRagPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLitertRagPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterLitertRagPlatform initialPlatform = FlutterLitertRagPlatform.instance;

  test('$MethodChannelFlutterLitertRag is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLitertRag>());
  });

  test('getPlatformVersion', () async {
    LiteRtRagEngine flutterLitertRagPlugin = LiteRtRagEngine();;
    MockFlutterLitertRagPlatform fakePlatform = MockFlutterLitertRagPlatform();
    FlutterLitertRagPlatform.instance = fakePlatform;

    // expect(await flutterLitertRagPlugin.getPlatformVersion(), '42');
  });
}
