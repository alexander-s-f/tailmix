# frozen_string_literal: true

module Tailmix
  module Definition
    module Scripting
      # Proxies for `this`. `this.item` -> `[:this, :item]`
      class ThisProxy
        def item
          # Returns a special marker that can be further expanded
          ExpressionBuilder.new([:this, :item])
        end
      end
    end
  end
end
