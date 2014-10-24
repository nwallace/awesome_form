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

        validate :models_to_save_are_valid

        def initialize(field_assignments={})
          model_assignments, other_assignments =
            validate_and_split_args!(field_assignments)
          super(model_assignments)
          self.class.reverse_assignment_rules.each do |rule|
            rule.perform(self)
          end
          super(other_assignments)
        end

        private

        def validate_and_split_args!(args)
          is_a_model = ->(key, val) { self.class.models_to_save.include?(key.to_sym) }
          model_assignments = args.select(&is_a_model)
          missing_args = self.class.models_to_save - model_assignments.keys.map(&:to_sym)
          unless missing_args.empty?
            raise ArgumentError, "Missing argument(s) #{missing_args.map(&:inspect).join(", ")}"
          end
          other_assignments = args.reject(&is_a_model)
          [model_assignments, other_assignments]
        end
      end
    end

    module ClassMethods
      def wraps(model, options={}, &block)
        attr_accessor model
        models_to_save << model # TODO: skip if not saving
        Wrapper.new(self, model, block).call
        delegate :to_model, to: model if options[:use_for_naming]
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

      def reverse_assignment_rules
        @reverse_assignment_rules ||= []
      end

      def add_assignment_rule(assignment_rule)
        assignment_rules << assignment_rule
      end

      def add_error_inclusion(error_inclusion)
        error_inclusions << error_inclusion
      end

      def add_reverse_assignment_rule(reverse_assignment_rule)
        reverse_assignment_rules << reverse_assignment_rule
      end
    end

    def save
      if valid?
        self.class.models_to_save
          .map {|model| public_send(model) }
          .compact
          .all?(&:save)
      end
    end

    def save!
      raise RecordInvalid unless save
    end

    protected

    def models_to_save_are_valid
      self.class.models_to_save.each do |model_name|
        if model=public_send(model_name)
          model.valid?
        end
      end
      self.class.error_inclusions.each do |inclusion|
        inclusion.include_errors(self)
      end
    end
  end

  class RecordInvalid < StandardError; end
end
