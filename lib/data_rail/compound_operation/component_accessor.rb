module DataRail
  module CompoundOperation

    class ComponentAccessor

      attr_reader :name, :options, :default

      def initialize(name, options = {}, &default)
        @name = name
        @options = options
        @default = default
      end

      def has_default?
        not default.nil?
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
