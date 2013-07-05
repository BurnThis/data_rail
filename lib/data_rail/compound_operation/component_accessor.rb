module DataRail
  module CompoundOperation

    class ComponentAccessor

      attr_reader :name, :options

      def initialize(name, options = {})
        @name = name
        @options = options
      end

      def read(object, name)
        object.instance_variable_get "@#{name}"
      end

      def write(object, name, value)
        object.instance_variable_set "@#{name}", value
      end

    end

  end
end
