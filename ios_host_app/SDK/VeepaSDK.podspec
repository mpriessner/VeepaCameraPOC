Pod::Spec.new do |s|
  s.name             = 'VeepaSDK'
  s.version          = '1.0.0'
  s.summary          = 'Veepa Camera SDK native library'
  s.description      = 'Native iOS library for Veepa camera P2P connection and video streaming'
  s.homepage         = 'https://github.com/mpriessner/VeepaCameraPOC'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'VeepaPOC' => 'dev@veepapoc.com' }
  s.source           = { :path => '.' }
  s.ios.deployment_target = '17.0'

  # Source files (plugin registration code)
  s.source_files = '*.{h,m}'
  s.public_header_files = 'VsdkPlugin.h', 'AppP2PApiPlugin.h', 'AppPlayerPlugin.h'

  # Native static library
  s.vendored_libraries = 'libVSTC.a'

  # Required frameworks
  s.frameworks = 'Foundation', 'UIKit', 'AVFoundation', 'VideoToolbox', 'AudioToolbox', 'CoreMedia', 'CoreVideo'
  s.libraries = 'z', 'c++', 'iconv', 'bz2'

  s.dependency 'Flutter'

  s.pod_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 x86_64'
  }
  s.user_target_xcconfig = {
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64 x86_64'
  }
end
