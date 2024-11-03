# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Rails::ActiveJobInitialize, :config do
  context 'with initialize method in ActiveJob' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        class MyJob < ApplicationJob
          def initialize(...)
          ^^^^^^^^^^^^^^ Avoid using `initialize` in ActiveJob. Move initialization logic to `before_perform` or `perform`.
            JobLogger.info('Job started')
            super
          end

          def perform
            # ...
          end
        end
      RUBY
    end
  end

  context 'with initialize method in a non-ActiveJob class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyService
          def initialize(...)
            JobLogger.info('Job started')
          end
        end
      RUBY
    end
  end

  context 'with before_perform or perform containing initialization logic' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class MyJob < ApplicationJob
          before_perform -> { JobLogger.info('Job started') }

          def perform
            # ...
          end
        end
      RUBY
    end
  end
end
