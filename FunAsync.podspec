Pod::Spec.new do |s|
  s.name = 'FunAsync'
  s.version = '0.1.0'
  s.summary = ''
  s.homepage = 'https://github.com/alexlin1976/FunAsync'
  s.license = 'MIT'
  s.author = 'alex'
  s.source = { :git => 'https://github.com/alexlin1976/FunAsync.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'

  s.source_files = 'sources/**/*.{h,swift}'
end
