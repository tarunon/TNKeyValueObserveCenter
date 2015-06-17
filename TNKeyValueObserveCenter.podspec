#
#  Be sure to run `pod spec lint TNKeyValueObserveCenter.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "TNKeyValueObserveCenter"
  s.version      = "0.0.2"
  s.summary      = "TNKeyValueObserveCenter is a Class for using Key-Value Observing like NSNotification."
  s.homepage     = "https://github.com/tarunon/TNKeyValueObserveCenter"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "tarunon" => "croissant9603@gmail.com" }
  s.ios.deployment_target = "5.0"
  s.osx.deployment_target = "10.8"
  s.source       = { :git => "https://github.com/tarunon/TNKeyValueObserveCenter.git", :branch => "master" }
  s.source_files  = "TNKeyValueObserveCenter", "TNKeyValueObserveCenter/*.{h,m}"
  s.requires_arc = true
end
