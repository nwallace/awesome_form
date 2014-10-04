module AwesomeForm
  class AssignmentRule
    def initialize(model_name, model_field, form_field)
      @model_name  = model_name
      @model_field = model_field
      @form_field  = form_field
    end

    def perform(form)
      # TODO: don't guard nil if required
      model = form.public_send(@model_name)
      if model
        value = if @form_field.respond_to?(:call)
                  case @form_field.arity
                  when 0; @form_field.call
                  when 1; @form_field.call(form)
                  else;   @form_field.call(form, model)
                  end
                else
                  form.public_send(@form_field)
                end
        model.public_send("#{@model_field}=", value)
      end
    end
  end
end
