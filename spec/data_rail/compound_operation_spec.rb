require 'data_rail/compound_operation'
require 'data_rail/compound_result'
require 'hashie/mash'

module DataRail

  class SuccessResult < Hashie::Mash
    def success?
      true
    end

    def executed?
      true
    end
  end

  class FailureResult < Hashie::Mash
    def success?
      false
    end

    def executed?
      true
    end
  end

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

  class NilResult

    def success?
      false
    end

    def executed?
      false
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

  class BillResult
    include CompoundResult

    components :prices, :subtotal, :tax, :tip, :total
  end

  class SubtotalOperation
    def call(prices)
      prices.inject :+
    end
  end

  class TaxOperation
    def call(subtotal)
      subtotal * 0.05
    end
  end

  class TipOperation
    def call(subtotal)
      subtotal * 0.15
    end
  end

  class TotalOperation
    def call(subtotal, tax, tip)
      subtotal + tax + tip
    end
  end

  class BillOperation
    include CompoundOperation

    #input_class BillResult

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
      let(:result) { BillResult.new(prices: [50, 25, 25]) }

      its(:total) { should eq 120 }
      it { should be_success }
      it { should be_executed }

      context 'when an intermediate operation fails' do
        let(:tax) { FailureOperation.new }

        it { should_not be_success }
        it { should_not be_executed }
      end
    end

  end

end
