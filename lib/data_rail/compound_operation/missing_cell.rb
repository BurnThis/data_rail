module DataRail

  CellMissingError = Class.new(StandardError)

  class MissingCell

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def call(*args)
      raise CellMissingError, "The #{name} cell is missing"
    end

    def call_on_result(result)
      raise CellMissingError, "The #{name} cell is missing"
    end

    def missing?
      true
    end

    def requires?(cell)
      false
    end

    def required_cell_names
      []
    end

  end
end
