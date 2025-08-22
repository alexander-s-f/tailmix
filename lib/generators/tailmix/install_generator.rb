# frozen_string_literal: true

require "rails/generators"

module Tailmix
  module Generators
    class InstallGenerator < Rails::Generators::Base
      def add_javascript
        say "Pinning Tailmix JavaScript", :green
        append_to_file "config/importmap.rb", <<~RUBY
          pin "tailmix/runner", to: "tailmix/runner.js"
        RUBY

        say "Adding Tailmix to asset manifest", :green
        append_to_file "app/assets/config/manifest.js", "\n//= link tailmix/runner.js\n"
      end
    end
  end
end
