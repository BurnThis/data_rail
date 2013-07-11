require 'data_rail/compound_operation'
require 'data_rail/compound_result'
require 'hashie/mash'


require_relative '../support/failure_result'
require_relative '../support/success_result'
require_relative '../support/nil_result'
require_relative '../support/mock_operation'

module DataRail

  FailureOperation = lambda { FailureResult.new }
  SuccessOperation = lambda { SuccessResult.new }

  class SimulatedBooking
    include CompoundOperation
    components :order, :charge
  end

  SubtotalOperation = lambda { |prices| prices.inject :+ }
  TaxOperation = lambda { |subtotal, tax_rate| subtotal * tax_rate }
  TipOperation = lambda { |subtotal, tip_rate| subtotal * tip_rate }
  TotalOperation = lambda { |subtotal, tax, tip| subtotal + tax + tip }

  class BillOperation
    include CompoundOperation

    components :total, :tax, :tip, :subtotal
  end


  describe CompoundOperation do

    let(:order) { SuccessOperation }
    let(:charge) { SuccessOperation }

    let(:operation) { SimulatedBooking.new(order: order, charge: charge) }

    let(:result) { Hashie::Mash.new }
    subject { result }

    before do
      operation.call(result)
    end

    context 'when all operations have been executed' do
      its(:order) { should be_a_kind_of SuccessResult }
      its(:charge) { should be_a_kind_of SuccessResult }
    end

    context 'when the charge operation is a failure' do
      let(:charge) { FailureOperation }

      its(:charge) { should be_a_kind_of FailureResult }
    end

    context 'with dependencies' do
      let(:subtotal) { SubtotalOperation }
      let(:tax) { TaxOperation }
      let(:tip) { TipOperation }
      let(:total) { TotalOperation }

      let(:operation) { BillOperation.new(subtotal: subtotal, tax: tax, tip: tip, total: total) }
      let(:result) { Hashie::Mash.new(prices: [50, 25, 25], tax_rate: 0.05, tip_rate: 0.15) }

      its(:subtotal) { should eq 100 }
      its(:tax) { should eq 5 }
      its(:tip) { should eq 15 }
      its(:total) { should eq 120 }

      context 'when a value with downstream dependencies changes' do
        let(:tax) { MockOperation.new [5, 100] }

        before do
          result.tax = nil
          operation.call(result)
        end

        its(:tax) { should eq 100 }
        its(:total) { should eq 215 }
      end

      context 'when an intermediate operation fails' do
        let(:tax) { MockOperation.new [FailureResult.new, 5] }

        its(:subtotal) { should_not be_nil }
        its(:tax) { should be_a_kind_of FailureResult }
        its(:total) { should be_nil }

        context 'when the intermediate operation succeeds on the 2nd try' do
          before do
            operation.call(result)
          end

          its(:total) { should eq 120 }
        end

      end

      #context 'when using a block for an operation' do
      #  class BlockOperation
      #    include CompoundOperation
      #
      #    component :math do |a, b|
      #      a + b
      #    end
      #  end
      #
      #  class BlockResult
      #    include CompoundResult
      #    component :a, :b, :math
      #  end
      #
      #  let(:operation) { BlockOperation.new }
      #  let(:result) { BlockResult.new(a: 3, b: 5) }
      #  subject { result }
      #  before do
      #    operation.call(result)
      #  end
      #
      #  its(:math) { should eq 8 }
      #end

    end

  end

end
