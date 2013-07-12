require 'data_rail/compound_operation/component'

module DataRail::CompoundOperation

  describe Cell do

    class Subtracter
      def call(a, b)
        a - b
      end
    end

    let(:options) { {} }
    let(:underlying_cell) { nil }
    let(:component) { Cell.new(underlying_cell, 'myoperation', options) }
    subject { component }

    context 'when creating from a lambda' do
      let(:underlying_cell) do
        lambda { |a, b| a + b }
      end

      its(:required_cell_names) { should eq [:a, :b] }
    end

    context 'when creating from a proc' do
      let(:underlying_cell) do
        Proc.new { |a, b| a + b }
      end

      its(:required_cell_names) { should eq [:a, :b] }
    end

    context 'when creating from a callable class' do
      let(:underlying_cell) { Subtracter.new }

      its(:required_cell_names) { should eq [:a, :b] }
    end

    context 'when mapping components' do
      let(:underlying_cell) { Subtracter.new }
      let(:options) do
        {
            inputs:
            {
                :discount => :b
            }
        }
      end

      its(:required_cell_names) { should eq [:a, :discount] }
    end

  end

end
