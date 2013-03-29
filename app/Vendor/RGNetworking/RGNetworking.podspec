Pod::Spec.new do |s|
  s.name             = "RGNetworking"
  s.version          = "1.0.1"
  s.summary          = "Useful wrapper around AFNetworking"
  s.homepage         = "http://ryangomba.com"
  s.license          = 'MIT'
  s.author           = {
    "Ryan Gomba" => "ryangomba@fb.com"
  }
  s.source           = {
    :git => "git@github.com:ryangomba/RGNetworking.git",
    :tag => s.version.to_s
  }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'RGNetworking/Classes'
  s.resource_bundles = {}

  s.dependency 'RGCore'
  s.dependency 'AFNetworking', '~> 2.3'
end
