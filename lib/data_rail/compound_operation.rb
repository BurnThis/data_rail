require 'tsort'
require 'set'
require 'delegate'

require 'data_rail/compound_operation/component'
require 'data_rail/compound_operation/component_accessor'

require 'pry'

module DataRail

  module CompoundOperation
    include TSort

    def self.included(base)
      base.extend ClassMethods
    end

    class Phase

      attr_reader :operations

      def initialize(operations)
        @operations = operations
      end

      def call_on_result(result)
        operations.map { |o| o.call_on_result(result) }
      end
    end

    class NilInput
      def self.new(object)
        object
      end
    end

    module ClassMethods

      def component_accessor(name)
        component_reader name
        component_writer name
      end

      def component_reader(name)
        accessors = component_accessors
        define_method name do
          accessors[name].read(self, name)
        end
      end

      def component_writer(name)
        accessors = component_accessors
        define_method "#{name}=" do |value|
          accessors[name].write(self, name, value)
        end
      end

      def component(name, options = {})
        component_accessor name
        accessor = ComponentAccessor.new(name.to_sym, options)
        component_accessors[accessor.name] = accessor
      end

      def components(*names)
        names.each { |n| component n }
      end

      def component_accessors
        @component_accessors ||= {}
      end

    end

    def initialize(components)
      components.each do |name, component|
        set_component name, component
      end
    end

    def call(result)
      result = coerce_result(result)
      each_component do |component|
        next if result.send(:get_component, component.name).success?
        component_result = component.call_on_result(result)
        break if not component_result.success?
      end

      result
    end

    def tsort_each_node(&block)
      unsorted_components.each(&block)
    end

    def tsort_each_child(component, &block)
      required_components_for(component).each(&block)
    end

    def input_class
      @input_class || NilInput
    end

    private

    #def phases
    #  strongly_connected_components.map { |components| Phase.new(components) }
    #end

    #def each_phase(&block)
    #  phases.each(&block)
    #end

    def coerce_result(result)
      if result.kind_of? input_class
        result
      else
        input_class.new(result)
      end
    end

    def required_components_for(component)
      component.required_component_names.map { |name| get_component(name) }.compact.uniq
    end

    def set_component(name, component)
      self.public_send "#{name}=", component
    end

    def get_component(name)
      unsorted_components.find { |c| c.name == name }
    end

    def each_component(&block)
      components.each(&block)
    end

    def components
      @components ||= tsort
    end

    def unsorted_components
      @unsorted_components ||= component_accessors.map { |d| new_component_from_accessor(d) }
    end

    def new_component_from_accessor(accessor)
      Component.new(public_send(accessor.name),
                    accessor.name,
                    accessor.options)
    end

    def component_accessors
      self.class.component_accessors.values
    end

  end
end
