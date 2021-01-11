#
# Be sure to run `pod lib lint TransnSDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TransnSDK'
  s.version          = '4.0.'
  s.summary          = '传神SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/jackie-jiang-ios/TransnSDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'jackie' => 'jackie.jiang@transn.com' }
  s.source           = { :git => 'https://github.com/jackie-jiang-ios/TransnSDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.0'

  s.source_files = 'TransnSDK/Classes/**/*'
  s.frameworks = [
           "AVFoundation",
           "AudioToolbox",
           "CoreMedia",
           "CoreTelephony",
           "SystemConfiguration",
           "VideoToolbox",
           "Accelerate",
           "CoreData",
           "AdSupport",
           "SystemConfiguration"
   ]
   s.source_files = 'TransnSDK/Classes/**/*{h,m}'
   s.public_header_files = 'TransnSDK/Classes/Public/**/*.h'

    s.xcconfig = {
          'VALID_ARCHS' => 'x86_64 armv7 arm64',
          'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
       }
 s.resource_bundles = {
    'TransnSDK' => ['TransnSDK/Assets/**/*{xcassets}','TransnSDK/Classes/**/*{xib,storyboard,mp3,plist,txt,xcdatamodeld}']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'XMPPFramework'
    s.dependency 'AgoraRtcEngine_iOS'
    s.dependency 'MagicalRecord'

    s.static_framework = true

end
