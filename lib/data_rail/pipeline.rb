require 'logger'

module DataRail
  class Pipeline

    def initialize(components, logger = Logger.new(nil))
      @components = components
      @logger = logger
    end

    def call(object)
      components.inject(object) { |o, component| call_component(component, o) }
    end

    def process(objects)
      objects.lazy.map { |o| call(o) }
    end

    private

    attr_reader :components, :logger

    def call_component(component, object)
      if arity(component) > 1
        component.call(object, logger)
      else
        component.call(object)
      end
    end

    def arity(operation)
      if operation.respond_to?(:arity)
        operation.arity
      else
        operation.method(:call).arity
      end
    end

  end
end
