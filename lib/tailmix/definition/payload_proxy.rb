# frozen_string_literal: true

module Tailmix
  module Definition
    # A marker indicating that the value should be taken from the runtime payload.
    PayloadValue = Struct.new(:key)

    # A proxy object that is passed to the `action do |payload|` block.
    # It creates PayloadValue markers instead of containing the actual data.
    class PayloadProxy
      def [](key)
        PayloadValue.new(key.to_sym)
      end
    end
  end
end
