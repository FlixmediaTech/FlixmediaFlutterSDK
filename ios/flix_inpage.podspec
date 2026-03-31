Pod::Spec.new do |s|
  s.name             = 'flix_inpage'
  s.version          = '1.0.0'
  s.summary          = 'Flutter iOS plugin that embeds FlixMediaFramework.'
  s.description      = <<-DESC
  Thin wrapper that exposes Flixmedia in-page content via an embedded XCFramework.
  DESC

  s.homepage         = 'https://github.com'
  s.license          = { :type => 'Proprietary', :file => '../LICENSE' }
  s.authors          = { 'Flixmedia' => 'ios@flixmedia.com' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '15.6'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_STRICT_CONCURRENCY' => 'minimal',
    'SWIFT_VERSION' => '5.10'
  }

  s.source_files     = 'Classes/**/*'
  s.resources      = ['Assets/*']
  s.vendored_frameworks = 'Resources/FlixMediaSDK.xcframework'

  s.dependency 'Flutter'
  s.static_framework = true
end
