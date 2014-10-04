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

      private

      def add_assignment_rules(assignments)
        assignment_rules.concat(assignments)
      end

      def assignment_rules
        @assignment_rules ||= []
      end
    end

    class Wrapper
      def initialize(form_class, model_name, block)
        @form_class = form_class
        @model_name = model_name
        @block = block
      end

      def call
        instance_eval(&@block)
      end

      def assigns(field_mappings)
        assignments = field_mappings.map do |model_field, form_field|
          Assignment.new(@model_name, model_field, form_field)
        end
        @form_class.send(:add_assignment_rules, assignments)
      end
    end

    class Assignment
      def initialize(model_name, model_field, form_field)
        @model_name  = model_name
        @model_field = model_field
        @form_field  = form_field
      end

      def perform(form)
        # TODO: don't guard nil if required
        model = form.public_send(@model_name)
        if model
          model.public_send("#{@model_field}=", form.public_send(@form_field))
        end
      end
    end
  end
end
