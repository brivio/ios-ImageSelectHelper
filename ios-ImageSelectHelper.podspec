Pod::Spec.new do |s|
  s.name             = "ios-ImageSelectHelper"
  s.version          = "0.1.0"
  s.summary          = "ImageSelectHelper for ios development"

  s.description      = <<-DESC
                       DESC
  s.homepage         = "https://github.com/brivio/ios-ImageSelectHelper"
  s.license          = 'MIT'
  s.author           = { "brivio" => "brivio@qq.com" }
  s.source           = { :git => "https://github.com/brivio/ios-ImageSelectHelper.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'source/**/*.{h,m,c}'
  s.resources='source/**/*.bundle'
  s.dependency 'LCActionSheet'
  s.dependency 'CocoaSecurity'
  s.frameworks='MobileCoreServices'
end
