#
# Be sure to run `pod lib lint Rockstar.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.ios.deployment_target = '11.0'
  s.name             = 'BSON'
  s.version          = '6.0.1'
  s.summary          = 'A Swift implementation of the BSON specification'

  s.description      = <<-DESC
APIs designed to parse/serialize as well as encode/decode BSON data.
                       DESC

  s.swift_version = '4.2'
  s.homepage         = 'https://github.com/OpenKitten/BSON'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'joannis' => 'joannis@orlandos.nl' }
  s.source           = { :git => 'https://github.com/OpenKitten/BSON.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/joannisorlandos'

  s.source_files     = 'Sources/BSON/**/*'
  s.dependency 'SwiftNIO', '>= 1.9.0'
end
