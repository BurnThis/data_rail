require 'virtus'

module DataRail

  module Processor

    IS_PROCESSOR = lambda { |processor| processor.respond_to?(:call) }
    IS_PROCESSOR_NAME = lambda { |processor| Processor.exists_by_name?(processor) }

    def self.exists_by_name?(processor_name)
      constants.include? class_name_of_processor(processor_name)
    end

    def self.class_name_of_processor(processor_name)
      camelize(processor_name.to_s).to_sym
    end

    def self.camelize(string)
      string.split('_').map { |w| w.capitalize }.join
    end

    def self.class_of_processor(processor_name)
      const_get class_name_of_processor(processor_name)
    end

    def self.coerce(processor)
      case processor
        when Array
          CompoundProcessor.new(processor)
        when IS_PROCESSOR
          processor
        when IS_PROCESSOR_NAME
          class_of_processor(processor).new
        else
          raise "Can't coerce #{processor.inspect} to a processor"
      end
    end

    class CompoundProcessor

      def initialize(processors)
        @processors = coerce_to_processors(processors)
      end

      def call(value)
        processors.inject(value) { |result, processor| processor.call(result) }
      end

      private

        attr_reader :processors

        def coerce_to_processors(processors)
          processors.map { |p| Processor.coerce(p) }
        end

    end

    class Strip
      def call(value)
        value.strip if value.respond_to?(:strip)
      end
    end

    class DollarsToCents
      def call(dollars)
        (dollars.to_f * 100).to_i if dollars.respond_to?(:to_f)
      end
    end

  end

  module Adapter

    class Field
      attr_reader :name, :options
      def initialize(name, options = {})
        @name = name
        @options = options
      end

      def read(data_source)
        value = from_components.inject(data_source, &method(:accessor))
        process(value)
      end

      protected

        def from_components
          from.to_s.split('.')
        end

        def from
          options[:from] || name
        end

        def processors
          options[:process] || []
        end

        def process(value)
          processor = Processor::coerce(processors)
          processor.call(value)
        end

        def accessor(object, property)
          if object.nil?
            nil
          else
            object.public_send(property) if object.respond_to?(property)
          end
        end

    end

    module ClassMethods

      def field(name, type, options = {})
        class_field_map[name] = Field.new(name, options)
        class_eval do
          attribute name, type
        end
      end

      def field_map
        superclass_field_map.merge(class_field_map).freeze
      end

      protected

      def class_field_map
        @field_map ||= {}
      end

      def superclass_field_map
        superclass.respond_to?(:field_map) ? superclass.field_map : {}
      end

    end

    def self.included(base)
      base.send :include, Virtus.model
      base.extend ClassMethods
    end

    attr_reader :data_source

    def fields
      self.class.field_map.values
    end

    def initialize(source)
      @data_source = Hashie::Mash.new(source)
      super(attributes_for_data_source @data_source)
    end

    private

      def attributes_for_data_source(data_source)
        attrs = Hashie::Mash.new
        fields.each { |f| attrs[f.name] = f.read(data_source) }
        attrs
      end

  end
end
