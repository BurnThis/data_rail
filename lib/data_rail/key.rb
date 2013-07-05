module DataRail
  class Key

    DEFAULT_DELIMITERS = ['/', ':']

    def self.from_s(string, delimiters = DEFAULT_DELIMITERS)
      if delimiters.empty?
        string
      else
        delimiter, *rest = delimiters
        components = string.split(delimiter).map { |c| Key.from_s(c, rest) }
        new(components, delimiter)
      end
    end

    def initialize(components, delimiter)
      @components = components
      @delimiter = delimiter
    end

    def [](first_index, *indexes)
      indexes.inject( components[first_index] ) { |key, index| key[index] }
    end

    def to_s
      components.join delimiter
    end

    private

    attr_reader :components, :delimiter

  end
end
