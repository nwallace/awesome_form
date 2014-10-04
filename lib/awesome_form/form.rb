module AwesomeForm
  module Form

    def self.included(klass)
      klass.extend ClassMethods
      klass.class_eval do
        include ActiveModel::Model
      end
    end

    module ClassMethods
      def wraps(obj, &block)
        attr_accessor obj
        yield
      end

      def fields(*fields)
        attr_accessor *fields
      end
    end
  end
end
