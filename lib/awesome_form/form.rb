module AwesomeForm
  module Form

    def self.included(klass)
      klass.extend ClassMethods
      klass.class_eval do
        include ActiveModel::Model
        include ActiveModel::Validations::Callbacks

        before_validation do |form|
          self.class.assignment_rules.each do |rule|
            rule.perform(form)
          end
        end

        after_validation do |form|
          self.class.models_to_save.each do |model_name|
            if model=form.public_send(model_name)
              model.valid?
            end
          end
          self.class.error_inclusions.each do |inclusion|
            inclusion.include_errors(form)
          end
        end
      end
    end

    module ClassMethods
      def wraps(model, &block)
        attr_accessor model
        models_to_save << model # TODO: skip if not saving
        Wrapper.new(self, model, block).call
      end

      def fields(*fields)
        attr_accessor *fields
      end

      def models_to_save
        @models_to_save ||= []
      end

      def assignment_rules
        @assignment_rules ||= []
      end

      def error_inclusions
        @error_inclusions ||= []
      end

      def add_assignment_rules(assignments)
        assignment_rules.concat(assignments)
      end

      def add_error_inclusions(inclusions)
        error_inclusions.concat(inclusions)
      end
    end

    def save
      self.class.models_to_save
        .map {|model| public_send(model) }
        .compact
        .all?(&:save)
    end

    def save!
      raise RecordInvalid unless save
    end
  end

  class RecordInvalid < StandardError; end
end
