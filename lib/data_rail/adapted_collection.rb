module DataRail
  class AdaptedCollection
    include Enumerable

    def initialize(collection, *adapters)
      @collection = collection
      @adapters = adapters_as_array(adapters)
    end

    def each
      collection.each { |o| yield wrap(o) }
    end

    private

      attr_reader :collection, :adapters

      def wrap(base_object)
        adapters.inject(base_object) { |object, adapter| adapter.new(object) }
      end

      def adapters_as_array(adapters)
        adapters.to_a.flatten.compact
      end

  end
end
