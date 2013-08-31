require 'data_rail/object_hasher'

module DataRail
  module Operation

    class UpdateRecord

      def initialize(active_record, options = {})
        @active_record = active_record
        @logger = options.fetch(:logger) { Logger.new(nil) }

        @fields = options[:fields] || {}
        @fields[:key] ||= ObjectHasher.new
      end

      def call(object)
        record = corresponding_record(object)
        attributes = attributes_for_object(object)
        assign_supported_attributes(record, attributes)

        record
      end

      private

      def attributes_for_object(object)
        object.attributes.merge(fields).merge fields_for_object(object)
      end

      def fields_for_object(object)
        Hash[ fields.map{ |k, v| [ k, v.respond_to?(:call) ? v.call(object) : v ] } ]
      end

      def assign_supported_attributes(record, attributes)
        attributes.each do |name, value|
          attr_writer = "#{name}="
          record.public_send(attr_writer, value) if record.respond_to?(attr_writer)
        end
      end

      def corresponding_record(object)
        active_record.where(key: key_for_object(object)).first_or_initialize
      end

      def key_for_object(object)
        fields[:key].call(object)
      end

      attr_reader :active_record, :fields, :logger

    end

  end
end