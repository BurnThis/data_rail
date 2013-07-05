require 'data_rail/compound_result/component'

module DataRail
  module CompoundResult

    class NilResult
      def success?
        false
      end

      def executed?
        false
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def component_reader(name)
        define_method name do
          instance_variable_get("@#{name}") || NilResult.new
        end
      end

      def component_writer(name)
        attr_writer name
      end

      def component_accessor(name)
        component_reader name
        component_writer name
      end

      def component(name)
        component_accessor name
        component_names << name.to_sym
      end

      def components(*names)
        names.each { |n| component n }
      end

      def component_names
        @components ||= Set.new
      end
    end

    def initialize(components = {})
      components.each do |name, component|
        set_component name, component
      end
    end

    def success?(name = nil)
      if name
        get_component(name).success?
      else
        all_components? &:success?
      end
    end

    def executed?(name = nil)
      if name
        get_component(name).executed?
      else
        all_components? &:executed?
      end
    end

    private

    def all_components?(&block)
      each_component.all?(&block)
    end

    def set_component(name, component)
      self.public_send "#{name}=", component
    end

    def get_component(name)
      Component.new(public_send(name), name)
    end

    def each_component(&block)
      components.each(&block)
    end

    def components
      component_names.map { |n| get_component(n) }
    end

    def component_names
      self.class.component_names
    end

  end
end
