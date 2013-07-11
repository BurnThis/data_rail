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

      def requires?(component)
        required_component_names.include? component.name
      end

      def required_component_names
        [*input_names , *preceeding_component_names].uniq
      end

      private

      attr_reader :options

      def preceeding_component_names
        options.fetch(:after) { [] }
      end

      def input_names
        parameter_pairs(object).map { |(type, name)| name if valid_input_type?(type) }.compact
      end

      def valid_input_type?(type)
        [:req, :opt].include? type
      end

      def parameter_pairs(object)
        if object.respond_to? :parameters
          object.parameters
        else
          object.method(:call).parameters
        end
      end

      def extract_attributes(object, attribute_names)
        attribute_names.map { |field| object.public_send(field) }
      end

    end

  end
end
