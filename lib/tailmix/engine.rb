# frozen_string_literal: true

module Tailmix
  class Engine < ::Rails::Engine
    config.before_initialize do
      Rails.application.config.assets.paths << Engine.root.join("app/javascript")
    end

    PRECOMPILE_ASSETS = %w[ index.js runner.js ]

    initializer "tailmix.assets" do
      if Rails.application.config.respond_to?(:assets)
        Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
      end
    end
  end
end
