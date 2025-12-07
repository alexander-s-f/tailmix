# frozen_string_literal: true

module Tailmix
  class DefinitionsController < ActionController::Base
    skip_forgery_protection only: :show

    def show
      Tailmix::ComponentStore.instance.refresh! if Rails.env.development? || params[:reload]
      store = Tailmix::ComponentStore.instance
      store.refresh! if store.version.empty?

      if stale?(etag: store.version, public: true)
        render js: store.to_js
      end
    end
  end
end
