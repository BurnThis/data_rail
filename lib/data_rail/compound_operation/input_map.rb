module DataRail
  module CompoundOperation

    class InputMap

      def initialize(inputs)
        self.inputs = flip(inputs || {})
      end

      def [](name)
        inputs.fetch(name) { name }
      end

      protected

      attr_accessor :inputs

      def flip(hash)
        Hash[hash.map(&:reverse)]
      end

    end

  end
end
