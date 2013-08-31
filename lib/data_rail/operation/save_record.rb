module DataRail
  module Operation

    class SaveRecord

      def initialize(logger = Logger.new(nil))
        @logger = logger
      end

      def call(record)
        new_record = record.new_record?
        record.save

        if new_record
          record_action 'CREATED', record
        else
          record_action 'UPDATED', record
        end
      end

      private

      attr_reader :logger

      def changed_attributes_summary(record)
        summary = []
        record.previous_changes.each_pair do |property, (old, new)|
          summary << "  CHANGED #{property}: #{old.inspect} => #{new.inspect}"
        end
        summary.join("\n")
      end

      def record_action(action, record)
        logger.info("#{action} #{record.class} [#{record.id}] #{record.name}")
        logger.info changed_attributes_summary(record)
      end

    end

  end
end