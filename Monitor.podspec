Pod::Spec.new do |spec|
  spec.name             = 'Monitor'
  spec.version          = '0.1'
  spec.license          = { :type => 'BSD', :file => 'LICENSE' }
  spec.homepage         = 'https://github.com/bobermaniac/Monitor'
  spec.authors          = { 'Victor Bryksin' => 'vbryksin@virtualmind.ru' }
  spec.summary          = 'Implementation of Observer pattern on steroids'
  spec.source           = { :git => 'https://github.com/bobermaniac/Monitor.git', :tag => 'v0.1' }
  spec.swift_versions = "5.0"
  spec.source_files     = 'Monitor/**/*.swift'
  spec.ios.deployment_target = '10.0'
  spec.osx.deployment_target = "10.12"
  spec.requires_arc     = true
end