# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'capistrano3-nginx'
  spec.version       = '2.1.6'
  spec.authors       = ['Juan Ignacio Donoso']
  spec.email         = ['jidonoso@gmail.com']
  spec.description   = %q{Adds suuport to nginx for Capistrano 3.x}
  spec.summary       = %q{Adds suuport to nginx for Capistrano 3.x}
  spec.homepage      = 'https://github.com/platanus/capistrano3-nginx'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'capistrano', '>= 3.0.0'

  spec.add_development_dependency 'rake'
end
