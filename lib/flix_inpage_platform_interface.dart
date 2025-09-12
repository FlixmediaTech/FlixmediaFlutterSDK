import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flix_inpage_method_channel.dart';

abstract class FlixInpagePlatform extends PlatformInterface {
  /// Constructs a FlixInpagePlatform.
  FlixInpagePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlixInpagePlatform _instance = MethodChannelFlixInpage();

  /// The default instance of [FlixInpagePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlixInpage].
  static FlixInpagePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlixInpagePlatform] when
  /// they register themselves.
  static set instance(FlixInpagePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
