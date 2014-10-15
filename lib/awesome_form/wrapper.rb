module AwesomeForm
  class Wrapper
    def initialize(form_class, model_name, block)
      @form_class = form_class
      @model_name = model_name
      @block = block
    end

    def call
      instance_eval(&@block)
    end

    def assigns(model_field, options)
      to = options.fetch(:to)
      rule = AssignmentRule.new(@model_name, model_field, to)
      @form_class.add_assignment_rule rule
      if options.fetch(:include_errors, to.is_a?(Symbol))
        inclusion = ErrorInclusion.new(@model_name, model_field, to)
        @form_class.add_error_inclusion inclusion
      end
    end
  end
end
