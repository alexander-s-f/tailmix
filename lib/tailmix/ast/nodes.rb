# lib/tailmix/ast/nodes.rb
# frozen_string_literal: true

module Tailmix
  module AST
    class Node
      def accept(visitor)
        visitor.visit(self)
      end

      def type_name
        self.class.name.split("::").last
      end
    end

    # Mixin для удобства, чтобы не дублировать accept в каждом классе
    module NodeMethods
      def accept(visitor)
        visitor.visit(self)
      end

      def type_name
        self.class.name.split("::").last
      end
    end

    # --- 1. Definitions ---
    Component = Struct.new(:name, :states, :elements, :boot_sequence, keyword_init: true) do
      include NodeMethods
    end

    StateDefinition = Struct.new(:name, :default_value, :type, keyword_init: true) do
      include NodeMethods
    end

    ElementDefinition = Struct.new(:name, :attributes, :rules, keyword_init: true) do
      include NodeMethods
    end

    # --- 2. Rules ---
    AttributeEffect = Struct.new(:classes, :data, :aria, :other, keyword_init: true) do
      include NodeMethods
    end

    StyleRule = Struct.new(:condition, :consequent, :alternate, keyword_init: true) do
      include NodeMethods
    end

    MatchRule = Struct.new(:subject, :cases, :default_case, keyword_init: true) do
      include NodeMethods
    end

    EventRule = Struct.new(:event_name, :instruction_sequence, keyword_init: true) do
      include NodeMethods
    end

    # --- 3. Instructions ---
    Block = Struct.new(:instructions, keyword_init: true) do
      include NodeMethods
    end

    Assignment = Struct.new(:target, :value, keyword_init: true) do
      include NodeMethods
    end

    Log = Struct.new(:arguments, keyword_init: true) do
      include NodeMethods
    end

    # --- 4. Expressions ---
    Literal = Struct.new(:value, keyword_init: true) do
      include NodeMethods
    end

    VariableReference = Struct.new(:domain, :path, keyword_init: true) do
      include NodeMethods
    end

    BinaryOp = Struct.new(:left, :operator, :right, keyword_init: true) do
      include NodeMethods
    end

    UnaryOp = Struct.new(:operator, :operand, keyword_init: true) do
      include NodeMethods
    end



    # Подключаем модуль ко всем структурам
    constants.each do |const|
      klass = const_get(const)
      klass.include(NodeMethods) if klass.is_a?(Class) && klass < Struct
    end
  end
end

# module Tailmix
#   module AST
#     # Базовый класс для всех узлов.
#     # Используем Data (Ruby 3.2+) или Struct для иммутабельности и простоты.
#     class Node
#       def accept(visitor)
#         visitor.visit(self)
#       end
#
#       # Хелпер для удобной дебаг-печати имени класса без модулей
#       def type_name
#         self.class.name.split("::").last
#       end
#     end
#
#     # --- 1. Definitions (Декларативная структура) ---
#
#     # Корневой узел компонента
#     class Component < Node
#       attr_reader :name, :states, :elements, :boot_sequence
#
#       def initialize(name:, states: [], elements: [], boot_sequence: [])
#         @name = name
#         @states = states
#         @elements = elements
#         @boot_sequence = boot_sequence # Инструкции при инициализации
#       end
#     end
#
#     # Определение стейта (например, state :count, default: 0)
#     class StateDefinition < Node
#       attr_reader :name, :default_value, :type
#
#       def initialize(name:, default_value:, type: :any)
#         @name = name
#         @default_value = default_value
#         @type = type
#       end
#     end
#
#     # Определение элемента UI (element :button)
#     class ElementDefinition < Node
#       attr_reader :name, :attributes, :rules
#
#       def initialize(name:, attributes: [], rules: [])
#         @name = name
#         @attributes = attributes # Базовые атрибуты (class, id и т.д.)
#         @rules = rules           # Динамические правила
#       end
#     end
#
#     # --- 2. Rules (Правила поведения элемента) ---
#
#     # Правило изменения классов (Dimension/Variant)
#     class StyleRule < Node
#       attr_reader :condition, :consequent, :alternate
#
#       def initialize(condition:, consequent:, alternate: nil)
#         @condition = condition
#         @consequent = consequent # Например, список классов
#         @alternate = alternate   # else ветка
#       end
#     end
#
#     # Привязка события (on :click)
#     class EventRule < Node
#       attr_reader :event_name, :instruction_sequence
#
#       def initialize(event_name:, instruction_sequence:)
#         @event_name = event_name
#         @instruction_sequence = instruction_sequence
#       end
#     end
#
#     # Правило Dimension (аналог switch/case)
#     # Позволяет мапить значение выражения на классы.
#     class MatchRule < Node
#       attr_reader :subject, :cases, :default_case
#
#       def initialize(subject:, cases:, default_case: nil)
#         @subject = subject       # Выражение (например, state.variant)
#         @cases = cases           # Hash: { "primary" => ["bg-red"], "secondary" => ["bg-blue"] }
#         @default_case = default_case # Массив классов для else, если нужно
#       end
#     end
#
#     # --- 3. Instructions (Императивные команды) ---
#
#     # Последовательность инструкций (блок кода)
#     class Block < Node
#       attr_reader :instructions
#
#       def initialize(instructions = [])
#         @instructions = instructions
#       end
#     end
#
#     # Присваивание (set state.foo, value)
#     class Assignment < Node
#       attr_reader :target, :value
#
#       def initialize(target:, value:)
#         @target = target
#         @value = value
#       end
#     end
#
#     # Логирование (log "foo")
#     class Log < Node
#       attr_reader :arguments
#
#       def initialize(arguments:)
#         @arguments = arguments
#       end
#     end
#
#     # --- 4. Expressions (Вычисляемые значения) ---
#
#     # Литерал (число, строка, булево)
#     class Literal < Node
#       attr_reader :value
#
#       def initialize(value)
#         @value = value
#       end
#     end
#
#     # Ссылка на переменную (state.count, param.id)
#     class VariableReference < Node
#       attr_reader :domain, :path # domain: :state/:param, path: [:count]
#
#       def initialize(domain:, path:)
#         @domain = domain
#         @path = path
#       end
#     end
#
#     # Бинарная операция (a + b, a == b)
#     class BinaryOp < Node
#       attr_reader :left, :operator, :right
#
#       def initialize(left:, operator:, right:)
#         @left = left
#         @operator = operator
#         @right = right
#       end
#     end
#   end
# end
