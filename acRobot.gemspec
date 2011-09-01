Gem::Specification.new do |s|
  s.name = 'acRobot'
  s.version = '0.1.0'
  s.summary = 'An acro IRC Bot implementation in Ruby using Cinch'
  s.description = 'A simple, friendly DSL for creating IRC bots'
  s.authors = ['Filip H.F. "FiXato" Slagter']
  s.email = ['fixato@gmail.com']
  s.homepage = 'https://github.com/FiXato/acRobot/'
  s.required_ruby_version = '>= 1.9.1'
  s.files = Dir['LICENSE', 'README.markdown', 'TODO.markdown', '{lib,bin,wordlists}/**/*']
  s.bindir = 'bin'
  s.add_dependency('cinch', '>= 1.1.3')
  s.license = 'MIT'
end