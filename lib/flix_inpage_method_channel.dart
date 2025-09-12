import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flix_inpage_platform_interface.dart';

/// An implementation of [FlixInpagePlatform] that uses method channels.
class MethodChannelFlixInpage extends FlixInpagePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flix_inpage');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
