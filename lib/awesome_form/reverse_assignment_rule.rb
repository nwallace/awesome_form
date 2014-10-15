module AwesomeForm
  class ReverseAssignmentRule
    def initialize(model_name, model_field, reversing)
      @model_name  = model_name
      @model_field = model_field
      @reversing  = reversing
    end

    def perform(form)
      # TODO: don't guard nil if required
      model = form.public_send(@model_name)
      if model
        if @reversing.respond_to?(:call)
          case @reversing.arity
          when 0; @reversing.call
          when 1; @reversing.call(form)
          else;   @reversing.call(form, model)
          end
        else
          model_value = model.public_send(@model_field)
          form.public_send("#{@reversing}=", model_value)
        end
      end
    end
  end
end
