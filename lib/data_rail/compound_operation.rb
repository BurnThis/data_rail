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

      def component(name, options = {}, &default)
        component_accessor name
        accessor = ComponentAccessor.new(name.to_sym, options, &default)
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
      each_component do |component|
        next if successful_result?(result)
        component_result = component.call_on_result(result)

        components_directly_dependent_on(component).each do |direct_component|
          result.public_send "#{direct_component.name}=", nil
        end

        break if not successful_result?(component_result)
      end

      result
    end

    def tsort_each_node(&block)
      unsorted_components.each(&block)
    end

    def tsort_each_child(component, &block)
      required_components_for(component).each(&block)
    end

    private

    def successful_result?(result)
      if result.respond_to? :success?
        result.success?
      else
        true
      end
    end

    def components_directly_dependent_on(component)
      components.select { |c| c.requires? component }
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
      underlying_component = public_send(accessor.name)
      if underlying_component
        Component.new(public_send(accessor.name),
                      accessor.name,
                      accessor.options)
      elsif accessor.has_default?
        Component.new(accessor.default,
                      accessor.name,
                      accessor.options)
      end
    end

    def component_accessors_with_defaults
      component_accessors.select { |a| a.has_default? }
    end

    def component_accessors
      self.class.component_accessors.values
    end

  end
end
