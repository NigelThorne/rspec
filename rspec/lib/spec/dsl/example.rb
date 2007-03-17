module Spec
  module DSL
    class Example

      class << self
        attr_accessor :current
        protected :current=

        callback_events :before_setup, :after_teardown
      end

      callback_events :before_setup, :after_teardown

      def initialize(name, opts={}, &example_block)
        @from = caller(0)[3]
        @options = opts
        @example_block = example_block
        @description = name
        setup_auto_generated_description
      end
      
      def setup_auto_generated_description
        description_generated = lambda { |desc| @generated_description = desc }
        before_setup do
          Spec::Matchers.register_callback(:description_generated, description_generated)
        end
        after_teardown do
          Spec::Matchers.unregister_callback(:description_generated, description_generated)
        end
      end

      def run(reporter, setup_block, teardown_block, dry_run, execution_context)
        reporter.spec_started(name) if reporter
        return reporter.spec_finished(name) if dry_run

        errors = []
        begin
          set_current
          setup_ok = setup_example(execution_context, errors, &setup_block)
          example_ok = run_example(execution_context, errors) if setup_ok
          teardown_ok = teardown_example(execution_context, errors, &teardown_block)
        ensure
          clear_current
        end

        ExampleShouldRaiseHandler.new(@from, @options).handle(errors)
        reporter.spec_finished(name, errors.first, failure_location(setup_ok, example_ok, teardown_ok)) if reporter
      end
      
      def matches?(matcher, criteria)
        matcher.example_desc = name
        matcher.matches?(criteria)
      end
      
    private
      def name
        @description == :__generate_description ? generated_description : @description
      end
      
      def generated_description
        @generated_description || "NAME NOT GENERATED"
      end
      
      def setup_example(execution_context, errors, &setup_block)
        notify_before_setup(errors)
        execution_context.setup_mocks if execution_context.respond_to?(:setup_mocks)
        execution_context.instance_eval(&setup_block) if setup_block
        return errors.empty?
      rescue => e
        errors << e
        return false
      end

      def run_example(execution_context, errors)
        begin
          execution_context.instance_eval(&@example_block)
          return true
        rescue Exception => e
          errors << e
          return false
        end
      end

      def teardown_example(execution_context, errors, &teardown_block)
        execution_context.instance_eval(&teardown_block) if teardown_block
        execution_context.teardown_mocks if execution_context.respond_to?(:teardown_mocks)
        notify_after_teardown(errors)
        return errors.empty?
      rescue => e
        errors << e
        return false
      end

      def notify_before_setup(errors)
        notify_class_callbacks(:before_setup, self, &append_errors(errors))
        notify_callbacks(:before_setup, self, &append_errors(errors))
      end
      
      def notify_after_teardown(errors)
        notify_callbacks(:after_teardown, self, &append_errors(errors))
        notify_class_callbacks(:after_teardown, self, &append_errors(errors))
      end
      
      def append_errors(errors)
        proc {|error| errors << error}
      end
      
      def set_current
        self.class.send(:current=, self)
      end

      def clear_current
        self.class.send(:current=, nil)
      end
      
      def failure_location(setup_ok, example_ok, teardown_ok)
        return 'setup' unless setup_ok
        return name unless example_ok
        return 'teardown' unless teardown_ok
      end
    end
  end
end
