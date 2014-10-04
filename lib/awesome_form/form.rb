module AwesomeForm
  module Form

    def self.included(klass)
      klass.extend ClassMethods
      klass.class_eval do
        include ActiveModel::Model
        include ActiveModel::Validations::Callbacks

        before_validation do |form|
          self.class.send(:assignment_rules).each do |rule|
            rule.perform(form)
          end
        end
      end
    end

    module ClassMethods
      def wraps(model, &block)
        attr_accessor model
        Wrapper.new(self, model, block).call
      end

      def fields(*fields)
        attr_accessor *fields
      end

      def add_assignment_rules(assignments)
        assignment_rules.concat(assignments)
      end

      private

      def assignment_rules
        @assignment_rules ||= []
      end
    end
  end
end
