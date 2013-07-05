require 'data_rail/logger/record_importer_logger'
require 'data_rail/object_hasher'

module DataRail
  class RecordImporter

    def initialize(active_record, options = {})
      @active_record = active_record

      @logger = options.fetch(:logger) { ::Logger.new(STDOUT) }
      @logger = Logger::RecordImportLogger.new(@logger)

      @fields = options[:fields] || {}
      @fields[:key] ||= ObjectHasher.new

      @observers = options[:observers] || []
    end

    def import(objects)
      logger.import_started
      objects.each { |o| self << o }
      logger.import_finished
    end

    def <<(object)
      record = corresponding_record(object)
      attributes = attributes_for_object(object)
      assign_supported_attributes(record, attributes)
      persist(record)
    end

    def add_observer(o)
      observers << o
    end

    private

    attr_reader :active_record, :logger, :key, :statistics, :fields, :observers

    def notify_observers(message, *args)
      observers_responding_to(message).each { |o| o.public_send(message, *args) }
    end

    def observers_responding_to(message)
      observers.select { |o| o.respond_to?(message) }
    end

    def persist(record)
      new_record = record.new_record?
      record.save

      if new_record
        logger.record_created(record)
      else
        logger.record_updated(record)
      end

      notify_observers(:after_save, record)
    end

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

  end
end
