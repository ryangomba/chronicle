Pod::Spec.new do |s|
  s.name             = "RGInterfaceKit"
  s.version          = "1.0.4"
  s.summary          = "UIView and UIScreen helpers"
  s.homepage         = "http://ryangomba.com"
  s.license          = 'MIT'
  s.author           = {
    "Ryan Gomba" => "ryan@ryangomba.com"
  }
  s.source           = {
    :git => "git@github.com:ryangomba/RGInterfaceKit.git",
    :tag => s.version.to_s
  }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resource_bundles = {}
end
