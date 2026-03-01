# frozen_string_literal: true

require_relative 'lib/jp_address_complement/version'

Gem::Specification.new do |spec|
  spec.name = 'jp_address_complement'
  spec.version = JpAddressComplement::VERSION
  spec.authors = ['naokirin']
  spec.email = ['naoki.rin186@gmail.com']

  spec.summary = 'Japanese address completion gem for Rails using postal code data'
  spec.description = 'A Rails gem that provides Japanese address completion and validation ' \
                     'based on Japan Post postal code CSV data. Supports address lookup by ' \
                     'postal code, prefix search, and address/postal code consistency validation.'
  spec.homepage = 'https://github.com/naokirin/jp_address_complement_rb'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'csv', '>= 3.0'
  spec.add_dependency 'rubyzip', '>= 2.3'

  spec.add_development_dependency 'activerecord', '>= 7.0'
  spec.add_development_dependency 'generator_spec', '~> 0.10'
  spec.add_development_dependency 'mysql2'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'railties', '>= 7.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rbs-inline', '~> 0.13'
  spec.add_development_dependency 'rbs_rails', '~> 0.13'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'sqlite3', '>= 2.0'
  spec.add_development_dependency 'steep', '~> 1.10'
end
