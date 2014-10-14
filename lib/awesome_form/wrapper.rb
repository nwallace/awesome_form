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

    def assigns(field_mappings)
      assignments = field_mappings.map do |model_field, form_field|
        AssignmentRule.new(@model_name, model_field, form_field)
      end
      @form_class.add_assignment_rules assignments
    end

    def includes_errors(field_mappings)
      inclusions = field_mappings.map do |model_field, form_field|
        ErrorInclusion.new(@model_name, model_field, form_field)
      end
      @form_class.add_error_inclusions inclusions
    end
  end
end
