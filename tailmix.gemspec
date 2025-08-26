# frozen_string_literal: true

require_relative "lib/tailmix/version"

Gem::Specification.new do |spec|
  spec.name = "tailmix"
  spec.version = Tailmix::VERSION
  spec.authors = [ "Alexander Fokin" ]
  spec.email = [ "alexander.s.fokin@gmail.com" ]

  spec.summary = "A declarative, state-driven attribute manager for Ruby UI components."
  spec.description = "Tailmix provides a powerful DSL to define component attribute schemas, including variants, compound variants, and states. It enables clean, co-located presentational logic (CSS classes, data attributes, ARIA roles) and offers a rich runtime API for dynamic manipulation, perfect for Hotwire/Turbo."
  spec.homepage = "https://github.com/alexander-s-f/tailmix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alexander-s-f/tailmix"
  spec.metadata["changelog_uri"] = "https://github.com/alexander-s-f/tailmix/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ "lib" ]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
