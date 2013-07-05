module DataRail
  module CompoundResult

    class Component < SimpleDelegator

      attr_reader :object, :name

      def initialize(object, name)
        @object = object
        @name = name.to_sym
        super(object)
      end

      def success?
        if object.respond_to? :success?
          object.success?
        else
          object != nil
        end
      end

      def executed?(name = nil)
        if object.respond_to? :executed?
          object.executed?
        else
          object != nil
        end
      end

    end

  end
end
