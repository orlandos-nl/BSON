Pod::Spec.new do |s|
  s.osx.deployment_target = '10.13'
  s.ios.deployment_target = '10.0'
  s.name             = 'BSON'
  s.version          = '7.0.4'
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
  s.dependency 'SwiftNIO', '~> 2.0'
end
