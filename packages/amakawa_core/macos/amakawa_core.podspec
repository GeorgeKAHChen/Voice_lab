Pod::Spec.new do |s|
  s.name             = 'amakawa_core'
  s.version          = '0.0.1'
  s.summary          = 'Low-latency audio engine and voice analysis for amakawa'
  s.description      = 'Full-duplex monitoring, recording, playback, spectrum and pitch analysis (miniaudio + C++ DSP).'
  s.homepage         = 'https://example.com'
  s.license          = { :type => 'MIT' }
  s.authors          = 'amakawa contributors'

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  # If your plugin requires a privacy manifest, for example if it collects user
  # data, update the PrivacyInfo.xcprivacy file to describe your plugin's
  # privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'amakawa_core_privacy' => ['amakawa_core/Sources/amakawa_core/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17', 'OTHER_LDFLAGS' => '-framework CoreAudio -framework AudioToolbox -framework CoreFoundation' }
  s.frameworks = 'CoreAudio', 'AudioToolbox', 'CoreFoundation'
  s.library = 'c++'
  s.swift_version = '5.0'
end
