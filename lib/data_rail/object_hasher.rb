module DataRail
  class ObjectHasher

    def initialize(prefix = nil)
      @prefix = prefix
    end

    def call(object)
      if prefix
        "#{prefix}/" + key(object)
      else
        key(object)
      end
    end

    private

    attr_reader :prefix

    def key(object)
      "#{object.source}:#{object.source_key}"
    end

  end

end
