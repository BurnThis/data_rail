require 'delegate'
require 'duration'

module DataRail
  module Logger

    class RecordImportLogger < SimpleDelegator

      attr_accessor :created, :updated

      def initialize(logger)
        @logger = logger
        super(@logger)

        reset!
      end

      def summary
        "CREATED #{created} RECORDS, UPDATED #{updated} RECORDS"
      end

      def import_started
        reset!
        logger.info 'STARTED IMPORT'

        self.import_started_at = now
      end

      def import_finished
        logger.info "FINISHED IMPORT #{summary}"
        logger.info time_elapsed_formatted
      end

      def record_created(record)
        logger.info("CREATED #{record.class} [#{record.id}] #{record.name}")
        logger.info changed_attributes_summary(record)

        self.created += 1
      end

      def record_updated(record)
        logger.info("UPDATED #{record.class} [#{record.id}] #{record.name}")
        logger.info changed_attributes_summary(record)

        self.updated += 1
      end

      private

      attr_reader :logger
      attr_accessor :import_started_at

      def now
        Time.now
      end

      def reset!
        self.created = 0
        self.updated = 0
      end

      def changed_attributes_summary(record)
        summary = []
        record.previous_changes.each_pair do |property, values|
          old, new = values
          summary << "  CHANGED #{property}: #{old.inspect} => #{new.inspect}"
        end
        summary.join("\n")
      end

      def time_elapsed_formatted
        Duration.from_times(import_started_at, now).to_s + ' elapsed'
      end

    end

  end
end
