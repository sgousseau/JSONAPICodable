Pod::Spec.new do |s|
  s.name             = 'JSONAPICodable'
  s.version          = '1.0.8'
  s.summary          = 'Json:api support for Swift Codable objects.'
 
  s.description      = <<-DESC
Json:api support for Swift Codable objects. WIP.
                       DESC
 
  s.homepage         = 'https://github.com/sgousseau/JSONAPICodable'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sébastien Gousseau' => 's.gousseau@gmail.com' }
  s.source           = { :git => 'https://github.com/sgousseau/JSONAPICodable.git', :tag => s.version.to_s }
 
  s.ios.deployment_target = '8.0'
  s.swift_version = '4.2'
  s.source_files = 'JSONAPICodable/*'
  s.exclude_files = 'JSONAPICodable/Info.plist'
 
end
