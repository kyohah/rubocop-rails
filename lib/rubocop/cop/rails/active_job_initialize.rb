# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Detects usage of `initialize` in ActiveJob subclasses and suggests moving
      # initialization logic to `before_perform` or `perform` method instead.
      #
      # @example
      #   # bad
      #   class MyJob < ApplicationJob
      #     def initialize
      #       JobLogger.info('Job started')
      #       super
      #     end
      #
      #     def perform
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class MyJob < ApplicationJob
      #     before_perform -> { JobLogger.info('Job started') }
      #
      #     def perform
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class MyJob < ApplicationJob
      #     def perform
      #       JobLogger.info('Job started')
      #       # ...
      #     end
      #   end
      #
      class ActiveJobInitialize < Base
        MSG = 'Avoid using `initialize` in ActiveJob. Move initialization logic to `before_perform` or `perform`.'

        # @!method initialize_method_in_active_job?(node)
        #   @param [RuboCop::AST::DefNode] node
        #   @return [Boolean]
        def_node_matcher :initialize_method_in_active_job?, <<~PATTERN
          (def :initialize ...)
        PATTERN

        # Checks if the `initialize` method is defined within an ActiveJob class.
        #
        # @param [RuboCop::AST::DefNode] node
        def on_def(node)
          return unless initialize_method_in_active_job?(node)

          # Checks if the class is a subclass of ApplicationJob
          class_node = node.ancestors.find(&:class_type?)
          return unless class_node&.parent_class&.const_name == 'ApplicationJob'

          add_offense(node)
        end
      end
    end
  end
end
