require 'logger'

module DataRail

  class PipelineBuilder

    def initialize
      @components = []
    end

    def build(logger = Logger.new(nil))
      Pipeline.new(components, logger)
    end

    def use(component)
      @components << component
    end

    private

    attr_reader :components

  end

  class Pipeline

    def self.build(logger = Logger.new(nil), &block)
      builder = PipelineBuilder.new
      builder.instance_eval(&block)
      builder.build(logger)
    end

    def initialize(components, logger = Logger.new(nil))
      @components = components
      @logger = logger
    end

    def call(object)
      components.inject(object) { |o, component| call_component(component, o) }
    end

    def process(objects)
      if block_given?
        objects.each { |o| yield call o }
      else
        objects.each { |o| call o }
      end

      nil
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
