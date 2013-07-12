require 'data_rail/compound_operation/component'

module DataRail::CompoundOperation

  describe Component do

    class Subtracter
      def call(a, b)
        a - b
      end
    end

    let(:options) { {} }
    let(:underlying_component) { nil }
    let(:component) { Component.new(underlying_component, 'myoperation', options) }
    subject { component }

    context 'when creating from a lambda' do
      let(:underlying_component) do
        lambda { |a, b| a + b }
      end

      its(:required_component_names) { should eq [:a, :b] }
    end

    context 'when creating from a proc' do
      let(:underlying_component) do
        Proc.new { |a, b| a + b }
      end

      its(:required_component_names) { should eq [:a, :b] }
    end

    context 'when creating from a callable class' do
      let(:underlying_component) { Subtracter.new }

      its(:required_component_names) { should eq [:a, :b] }
    end

    context 'when mapping components' do
      let(:underlying_component) { Subtracter.new }
      let(:options) do
        {
            inputs:
            {
                :discount => :b
            }
        }
      end

      its(:required_component_names) { should eq [:a, :discount] }
    end

  end

end
