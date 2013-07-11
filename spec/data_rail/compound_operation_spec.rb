require 'data_rail/compound_operation'
require 'data_rail/compound_result'
require 'hashie/mash'


require_relative '../support/failure_result'
require_relative '../support/success_result'
require_relative '../support/nil_result'
require_relative '../support/mock_operation'

module DataRail

  class SuccessOperation
    def call
      SuccessResult.new
    end
  end

  class FailureOperation
    def call
      FailureResult.new
    end
  end

  class SimulatedBookingResult
    include CompoundResult

    components :order, :charge, :roster
  end

  class SimulatedBooking
    include CompoundOperation

    components :order, :charge, :roster
  end

  class SubtotalOperation
    def call(prices)
      prices.inject :+
    end
  end

  class TaxOperation
    def call(subtotal, tax_rate)
      subtotal * tax_rate
    end
  end

  class TipOperation
    def call(subtotal, tip_rate)
      subtotal * tip_rate
    end
  end

  class TotalOperation
    def call(subtotal, tax, tip)
      subtotal + tax + tip
    end
  end

  class BillOperation
    include CompoundOperation

    components :total, :tax, :tip, :subtotal
  end

  describe CompoundOperation do

    let(:order) { SuccessOperation.new }
    let(:charge) { SuccessOperation.new }
    let(:roster) { SuccessOperation.new }

    let(:operation) { SimulatedBooking.new(order: order, charge: charge, roster: roster) }

    let(:result) { SimulatedBookingResult.new }
    subject { result }

    before do
      operation.call(result)
    end

    context 'when all operations are successful' do
      it { should be_success }
    end

    context 'when the charge operation is a failure' do
      let(:charge) { FailureOperation.new }

      it { should_not be_success }
      it { should_not be_executed }
    end

    context 'with dependencies' do
      let(:subtotal) { SubtotalOperation.new }
      let(:tax) { TaxOperation.new }
      let(:tip) { TipOperation.new }
      let(:total) { TotalOperation.new }

      let(:operation) { BillOperation.new(subtotal: subtotal, tax: tax, tip: tip, total: total) }
      let(:result) { Hashie::Mash.new(prices: [50, 25, 25], tax_rate: 0.05, tip_rate: 0.15) }

      its(:total) { should eq 120 }
      it { should be_success }
      it { should be_executed }

      context 'when a value with downstream dependencies changes' do
        let(:tax) { MockOperation.new [5, 100] }

        before do
          result.tax = nil
          operation.call(result)
        end

        its(:total) { should eq 215 }
      end

      context 'when an intermediate operation fails' do
        let(:tax) { MockOperation.new [FailureResult.new, 5] }

        it { should_not be_success }
        it { should_not be_executed }

        it { should be_executed :tax }
        # should execute all the operations in a phase
        # it { should be_success :tip }

        context 'when the intermediate operation succeeds on the 2nd try' do
          before do
            operation.call(result)
          end

          it { should be_success }
          it { should be_executed }

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
