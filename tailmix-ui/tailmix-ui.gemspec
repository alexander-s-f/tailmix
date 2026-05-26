# frozen_string_literal: true

require_relative "lib/tailmix_ui/version"

Gem::Specification.new do |spec|
  spec.name = "tailmix-ui"
  spec.version = TailmixUi::VERSION
  spec.authors = [ "Alexander Fokin" ]
  spec.email = [ "alexander.s.fokin@gmail.com" ]

  spec.summary = "Pre-built, reactive Arbre + Tailwind CSS components powered by Tailmix."
  spec.description = "TailmixUi provides premium, accessible, and reactive UI components built with Arbre and Tailwind CSS, completely powered by the state-driven Tailmix engine. Free of custom JavaScript or Stimulus."
  spec.homepage = "https://github.com/alexander-s-f/tailmix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/alexander-s-f/tailmix"
  spec.metadata["changelog_uri"] = "https://github.com/alexander-s-f/tailmix/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ test/ spec/ features/ .git])
    end
  rescue Errno::ENOENT
    # Fallback if git is not available or not inside a repo
    Dir.glob("lib/**/*") + %w[Gemfile LICENSE.txt README.md Rakefile]
  end
  spec.require_paths = [ "lib" ]

  spec.add_dependency "arbre", ">= 1.5.0"
  spec.add_dependency "tailmix", ">= 0.4.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
