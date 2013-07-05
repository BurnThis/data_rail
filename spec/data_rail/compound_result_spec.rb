require 'data_rail/compound_result'

module DataRail

  class SuccessResult
    def success?
      true
    end

    def executed?
      true
    end
  end

  class FailureResult
    def success?
      false
    end

    def executed?
      true
    end
  end

  class TestCompoundBookingResult
    include CompoundResult

    components :order, :charge, :roster
  end

  describe CompoundResult do
    let(:order) { SuccessResult.new }
    let(:charge) { SuccessResult.new }
    let(:roster) { SuccessResult.new }

    let(:result) { TestCompoundBookingResult.new(order: order, charge: charge, roster: roster) }
    subject { result }

    context 'when all the results are successful' do
      it { should be_success }
      it { should be_executed }

      it { should be_success :order }
      it { should be_success :charge }
      it { should be_success :roster }
    end

    context 'when a result is a failure' do
      let(:charge) { FailureResult.new }

      it { should_not be_success }
      it { should be_executed }
    end

    context 'when a result is nil' do
      let(:charge) { nil }

      it { should_not be_success }
      it { should_not be_executed }

      it { should be_executed :order }
      it { should_not be_executed :charge }
    end

  end

end
