# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Looks for enums written with keyword arguments syntax.
      #
      # Defining enums with keyword arguments syntax is deprecated and will be removed in Rails 8.0.
      # Positional arguments should be used instead:
      #
      # @example
      #   # bad
      #   enum status: { active: 0, archived: 1 }, _prefix: true
      #
      #   # good
      #   enum :status, { active: 0, archived: 1 }, prefix: true
      #
      class EnumSyntax < Base
        extend AutoCorrector
        extend TargetRailsVersion

        minimum_target_rails_version 7.0

        MSG = 'Enum defined with keyword arguments in `%<enum>s` enum declaration. Use positional arguments instead.'
        MSG_OPTIONS = 'Enum defined with deprecated options in `%<enum>s` enum declaration. Remove the `_` prefix.'
        RESTRICT_ON_SEND = %i[enum].freeze
        OPTION_NAMES = %w[prefix suffix scopes default].freeze

        def_node_matcher :enum?, <<~PATTERN
          (send nil? :enum (hash $...))
        PATTERN

        def_node_matcher :enum_with_options?, <<~PATTERN
          (send nil? :enum $_ ${array hash} $_)
        PATTERN

        def_node_matcher :enum_values, <<~PATTERN
          (pair $_ ${array hash})
        PATTERN

        def_node_matcher :enum_options, <<~PATTERN
          (pair $_ $_)
        PATTERN

        def on_send(node)
          check_and_correct_keyword_args(node)
          check_enum_options(node)
        end

        private

        def check_and_correct_keyword_args(node)
          enum?(node) do |pairs|
            pairs.each do |pair|
              key, values = enum_values(pair)
              next unless key

              correct_keyword_args(node, key, values, pairs[1..])
            end
          end
        end

        def check_enum_options(node)
          enum_with_options?(node) do |key, _, options|
            options.children.each do |option|
              name, = enum_options(option)

              add_offense(name, message: format(MSG_OPTIONS, enum: enum_name_value(key))) if name.source[0] == '_'
            end
          end
        end

        def correct_keyword_args(node, key, values, options)
          add_offense(values, message: format(MSG, enum: enum_name_value(key))) do |corrector|
            # TODO: Multi-line autocorrect could be implemented in the future.
            next if multiple_enum_definitions?(node)

            preferred_syntax = "enum #{enum_name(key)}, #{values.source}#{correct_options(options)}"

            corrector.replace(node, preferred_syntax)
          end
        end

        def multiple_enum_definitions?(node)
          keys = node.first_argument.keys.map { |key| key.source.delete_prefix('_') }
          filterred_keys = keys.filter { |key| !OPTION_NAMES.include?(key) }
          filterred_keys.size >= 2
        end

        def enum_name_value(key)
          case key.type
          when :sym, :str
            key.value
          else
            key.source
          end
        end

        def enum_name(elem)
          case elem.type
          when :str
            elem.value.dump
          when :sym
            elem.value.inspect
          else
            elem.source
          end
        end

        def correct_options(options)
          corrected_options = options.map do |pair|
            name = if pair.key.source[0] == '_'
                     pair.key.source[1..]
                   else
                     pair.key.source
                   end

            "#{name}: #{pair.value.source}"
          end.join(', ')

          ", #{corrected_options}" unless corrected_options.empty?
        end
      end
    end
  end
end
