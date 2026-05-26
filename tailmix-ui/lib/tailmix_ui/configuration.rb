# frozen_string_literal: true

module TailmixUi
  class Configuration
    attr_accessor :icon_provider, :icon_storage_path, :icon_renderer, :state_mappings

    def initialize
      @icon_provider = :custom
      @icon_storage_path = "app/assets/icons"
      @icon_renderer = ->(name, options = {}) {
        if defined?(Rails)
          path = Rails.root.join(@icon_storage_path, "#{name}.svg")
          if File.exist?(path)
            File.read(path).html_safe
          else
            "<!-- Icon '#{name}' not found at #{path} -->".html_safe
          end
        else
          "<!-- Icon '#{name}' (No Rails) -->".html_safe
        end
      }

      # Pre-populated semantic state mappings
      @state_mappings = {
        green: %w[active completed available answered applied deposit prepaid postpaid marketing initial_order delivered call_connected square no_dispute resolved current success yes good],
        yellow: %w[pending estimate pending_approval ringing fully_refunded partially_refunded],
        blue: %w[auto call_center outbound planned initial update technician output contract],
        sky: %w[manager commercial high_end inbound],
        indigo: %w[marketing_and_call_center technician_manager spark],
        red: %w[inactive failed missed charge suspended canceled cancel no_conversion wrong_zip eta_status wrong_appliance wrong_number abandoned wrong_service fired discarded not_connected not_set unset requested no bad spam poor],
        cyan: %w[residential composition],
        pink: %w[rejected manual],
        purple: %w[overdue no_call under_review],
        fuchsia: %w[admin],
        emerald: %w[input],
        teal: %w[ended]
      }
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
