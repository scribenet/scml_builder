spec = Gem::Specification.new do |s| 
  s.name = 'scml_builder'
  s.version = '0.0.1'
  s.author = 'Dan Corrigan'
  s.email = 'dcorrigan@scribenet.com'
  s.homepage = 'http://scribenet.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A CLI tool for producing WFDW expressions of the ScML list'
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.files = Dir.glob("{bin,lib,xsl,static,etc}/**/*")
  s.executables << 'scml_builder'
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('pry')
  s.add_development_dependency('mocha')
  s.add_development_dependency('minitest', '> 5.0.0')
  s.add_runtime_dependency('docx_tools')
end
