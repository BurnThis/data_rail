module DataRail
  class MockOperation
    attr_reader :queue

    def initialize(queue = [])
      @queue = queue
    end

    def <<(result)
      queue << result
    end

    def call
      queue.shift
    end

  end
end
