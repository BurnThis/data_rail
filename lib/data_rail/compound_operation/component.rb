require 'delegate'

require 'data_rail/compound_result/component'

module DataRail
  module CompoundOperation

    class InputMap

      def initialize(inputs)
        self.inputs = flip(inputs || {})
      end

      def [](name)
        inputs.fetch(name) { name }
      end

      protected

      attr_accessor :inputs

      def flip(hash)
        Hash[hash.map(&:reverse)]
      end

    end

    class Component < SimpleDelegator

      attr_reader :object, :name

      def initialize(object, name, options = {})
        @object = object
        @name = name.to_sym
        @after = options.fetch(:after) { [] }
        @input_map = InputMap.new(options[:inputs])

        super(object)
      end

      def call(*args)
        super
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

      protected

      attr_reader :input_map, :after

      private

      def preceeding_component_names
        self.after
      end

      def input_names
        transform_input_names base_input_names
      end

      def base_input_names
        parameter_pairs(object).map { |(type, name)| name if valid_input_type?(type) }.compact
      end

      def transform_input_names(input_names)
        input_names.map { |name| input_map[name] }
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
