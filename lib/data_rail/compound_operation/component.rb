require 'data_rail/compound_result/component'

module DataRail
  module CompoundOperation

    class Component < SimpleDelegator

      attr_reader :object, :name

      def initialize(object, name, options = {})
        @object = object
        @name = name.to_sym
        @options = options
        super(object)
      end

      def call_on_result(result)
        attributes = extract_attributes(result, input_names)
        result_component = call(*attributes)
        result.public_send "#{name}=", result_component

        CompoundResult::Component.new(result_component, name)
      end

      def required_component_names
        input_names
      end

      private

      def input_names
        parameter_names(object, :call)
      end

      def parameter_names(object, method)
        object.method(method).parameters.map { |(_, name)| name }
      end

      def extract_attributes(object, attribute_names)
        attribute_names.map { |field| object.public_send(field) }
      end

    end

  end
end
