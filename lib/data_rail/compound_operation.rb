require 'tsort'
require 'set'
require 'delegate'

require 'data_rail/compound_operation/cell'
require 'data_rail/compound_operation/cell_accessor'

require 'pry'

module DataRail

  module CompoundOperation
    include TSort

    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      def cell_accessor(name)
        cell_reader name
        cell_writer name
      end

      def cell_reader(name)
        accessors = cell_accessors
        define_method name do
          accessors[name].read(self, name)
        end
      end

      def cell_writer(name)
        accessors = cell_accessors
        define_method "#{name}=" do |value|
          accessors[name].write(self, name, value)
        end
      end

      def cell(name, options = {}, &default)
        cell_accessor name
        accessor = CellAccessor.new(name.to_sym, options, &default)
        cell_accessors[accessor.name] = accessor
      end

      def cells(*names)
        names.each { |n| cell n }
      end

      def cell_accessors
        @cell_accessors ||= {}
      end

    end

    def initialize(cells = {})
      cells.each do |name, cell|
        set_cell name, cell
      end
    end

    def call(result)
      check_for_missing_cells!

      each_cell do |cell|
        next if successful_result? result.public_send(cell.name)
        cell_result = cell.call_on_result(result)

        cells_directly_dependent_on(cell).each do |neighboring_cell|
          result.public_send "#{neighboring_cell.name}=", nil
        end

        break if not successful_result?(cell_result)
      end

      result
    end

    def tsort_each_node(&block)
      unordered_cells.each(&block)
    end

    def tsort_each_child(cell, &block)
      required_cells_for(cell).each(&block)
    end

    private

    SUPPORTS_SUCCESS = lambda { |object| object.respond_to? :success? }

    def successful_result?(result)
      case result
        when SUPPORTS_SUCCESS
          result.success?
        when nil
          false
        else
          true
      end
    end

    def cells_directly_dependent_on(cell)
      cells.select { |c| c.requires? cell }
    end

    def required_cells_for(cell)
      cell.required_cell_names.map { |name| get_cell(name) }.compact.uniq
    end

    def set_cell(name, cell)
      self.public_send "#{name}=", cell
    end

    def get_cell(name)
      unordered_cells.find { |c| c.name == name }
    end

    def each_cell(&block)
      cells.each(&block)
    end

    def cells
      @cells ||= tsort
    end

    def check_for_missing_cells!
      raise CellMissingError, "Missing cells: #{missing_cell_names.join(', ')}" if missing_cells?
    end

    def missing_cells?
      !missing_cells.empty?
    end

    def missing_cells
      cells.select &:missing?
    end

    def missing_cell_names
      missing_cells.map &:name
    end

    def unordered_cells
      @unordered_cells ||= cell_accessors.map { |d| new_cell_from_accessor(d) }
    end

    def new_cell_from_accessor(accessor)
      underlying_component = public_send(accessor.name)
      if underlying_component
        Cell.new(underlying_component, accessor.name, accessor.options)
      elsif accessor.has_default?
        Cell.new(accessor.default, accessor.name, accessor.options)
      else
        MissingCell.new(accessor.name)
      end
    end

    def cell_accessors_with_defaults
      component_accessors.select { |a| a.has_default? }
    end

    def cell_accessors
      self.class.cell_accessors.values
    end

  end
end
