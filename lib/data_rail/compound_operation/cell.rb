require 'delegate'

require 'data_rail/compound_result/component'
require 'data_rail/compound_operation/input_map'
require 'data_rail/compound_operation/missing_cell'

module DataRail
  module CompoundOperation

    class Cell < SimpleDelegator

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
        cell_result = call(*attributes)
        result.public_send "#{name}=", cell_result
      end

      def requires?(cell)
        required_cell_names.include? cell.name
      end

      def required_cell_names
        [*input_names , *preceeding_cell_names].uniq
      end

      def missing?
        false
      end

      protected

      attr_reader :input_map, :after

      private

      def preceeding_cell_names
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
        attribute_names.map do |field|
          result = object.public_send(field)
          raise "#{field} is nil" if result.nil?
          result
        end
      end

    end

  end
end
