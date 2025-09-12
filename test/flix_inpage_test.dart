import 'package:flutter_test/flutter_test.dart';
import 'package:flix_inpage/flix_inpage.dart';
import 'package:flix_inpage/flix_inpage_platform_interface.dart';
import 'package:flix_inpage/flix_inpage_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlixInpagePlatform
    with MockPlatformInterfaceMixin
    implements FlixInpagePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlixInpagePlatform initialPlatform = FlixInpagePlatform.instance;

  test('$MethodChannelFlixInpage is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlixInpage>());
  });

  test('getPlatformVersion', () async {
    FlixInpage flixInpagePlugin = FlixInpage();
    MockFlixInpagePlatform fakePlatform = MockFlixInpagePlatform();
    FlixInpagePlatform.instance = fakePlatform;

    expect(await flixInpagePlugin.getPlatformVersion(), '42');
  });
}
