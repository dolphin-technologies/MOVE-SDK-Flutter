#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint movesdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'movesdk'
  s.version          = '2.6.7'
  s.summary          = 'Dolphin MOVE SDK'
  s.description      = 'Wrapper for the Dolphin MoveSDk'
  s.homepage         = 'https://movesdk.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dolphin Technologies GmbH' => 'info@dolph.in' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'

  s.dependency 'Flutter'
  s.dependency 'DolphinMoveSDK', '2.6.7.275'

  s.platform = :ios, '11.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
