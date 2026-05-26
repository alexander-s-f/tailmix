# frozen_string_literal: true

module TailmixUi
  module Components
    # The Tailmix CVA (Class Variance Authority) state and variant configuration for Badge.
    class BadgeState
      include Tailmix
      attr_reader :ui

      tailmix do
        variant :size, default: :default
        variant :color, default: :default

        element :container, "font-medium rounded whitespace-nowrap" do
          match variant.size do
            on :default, "text-base px-2.5 py-0.5"
            on :xs, "text-xs px-1.5 py-0.5"
            on :sm, "text-sm px-2 py-0.5"
            on :md, "text-base px-2.5 py-0.5"
            on :lg, "text-lg px-3 py-1"
            on :xl, "text-xl px-3 py-1"
          end

          match variant.color do
            on :default, "bg-gray-700 text-gray-300"
            on :gray, "bg-gray-800 text-gray-300"
            on :danger, "bg-red-900 text-red-300"
            on :success, "bg-green-900 text-green-300"
            on :warning, "bg-yellow-900 text-yellow-300"
            on :primary, "bg-blue-900 text-blue-300"
            on :info, "bg-sky-900 text-sky-300"
            on :indigo, "bg-indigo-900 text-indigo-300"
            on :purple, "bg-purple-900 text-purple-300"
            on :pink, "bg-pink-900 text-pink-300"
            on :cyan, "bg-cyan-900 text-cyan-300"
            on :fuchsia, "bg-fuchsia-900 text-fuchsia-300"
            on :emerald, "bg-emerald-900 text-emerald-300"
            on :teal, "bg-teal-700 text-teal-100"

            # Aliases
            on :green, "bg-green-900 text-green-300"
            on :red, "bg-red-900 text-red-300"
            on :yellow, "bg-yellow-900 text-yellow-300"
            on :blue, "bg-blue-900 text-blue-300"
            on :sky, "bg-sky-900 text-sky-300"
          end
        end
      end

      def initialize(size:, color:)
        @ui = tailmix(size: size, color: color)
      end
    end

    # The Arbre component for rendering Badge.
    class Badge < BaseComponent
      builder_method :badge

      def tag_name
        "span"
      end

      def build(value, options = {})
        classes = options.delete(:class)
        size = options.delete(:size) || :default
        state = options.delete(:state) || options.delete(:color)

        resolved_value = convert_to_status(value)
        content_text = options.fetch(:titleize, true) ? resolved_value.to_s.titleize : resolved_value.to_s

        resolved_state = auto_state(value, state)

        # Dynamically build state/facade using BadgeState
        @badge_ui = BadgeState.new(size: size, color: resolved_state).ui

        super(@badge_ui.container(options))

        add_class("mx-0.5")
        add_class(classes) if classes

        span content_text, class: "badge-content"
      end

      private

      def convert_to_status(status)
        case status
        when true, "true", 1, "1" then "Yes"
        when false, "false", 0, "0" then "No"
        when nil then "Unset"
        else status
        end
      end

      def auto_state(value, state)
        return state if state.present?

        case value
        when true, "true", 1, "1" then :green
        when false, "false", 0, "0" then :red
        when nil then :yellow
        else state_by_value(value)
        end
      end

      def state_by_value(value)
        val = value.to_s.parameterize.underscore
        green = %w[active completed available answered applied deposit prepaid postpaid marketing initial_order delivered call_connected square no_dispute resolved current success yes good]
        yellow = %w[pending estimate pending_approval ringing fully_refunded partially_refunded]
        blue = %w[auto call_center outbound planned initial update technician output contract]
        sky = %w[manager commercial high_end inbound]
        indigo = %w[marketing_and_call_center technician_manager spark]
        red = %w[inactive failed missed charge suspended canceled cancel no_conversion wrong_zip eta_status wrong_appliance wrong_number abandoned wrong_service fired discarded not_connected not_set unset requested no bad spam poor]
        cyan = %w[residential composition]
        pink = %w[rejected manual]
        purple = %w[overdue no_call under_review]
        fuchsia = %w[admin]
        emerald = %w[input]
        teal = %w[ended]

        case val
        when *green then :green
        when *indigo then :indigo
        when *yellow then :yellow
        when *red then :red
        when *blue then :blue
        when *cyan then :cyan
        when *pink then :pink
        when *purple then :purple
        when *fuchsia then :fuchsia
        when *sky then :sky
        when *emerald then :emerald
        when *teal then :teal
        else :default
        end
      end
    end
  end
end
