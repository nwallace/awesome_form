module AwesomeForm
  class ErrorInclusion
    def initialize(model_name, model_field, form_field)
      @model_name  = model_name
      @model_field = model_field
      @form_field  = form_field
    end

    def include_errors(form)
      # TODO: don't guard nil if required
      if model=form.public_send(@model_name)
        model.errors[@model_field].each do |error|
          form.errors.add(@form_field, error)
        end
      end
    end
  end
end
