Pod::Spec.new do |s|
  s.name             = "RGCore"
  s.version          = "1.0.4"
  s.summary          = "Asserts, Logs, Timers, Macros, etc."
  s.homepage         = "http://ryangomba.com"
  s.license          = 'MIT'
  s.author           = {
    "Ryan Gomba" => "ryan@ryangomba.com"
  }
  s.source           = {
    :git => "git@github.com:ryangomba/RGCore.git",
    :tag => s.version.to_s
  }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Headers'
  s.resource_bundles = {}
end
