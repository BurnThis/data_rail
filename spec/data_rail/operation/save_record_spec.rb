require 'spec_helper'

require 'data_rail/operation/save_record'
require 'hashie/mash'

require 'logger'

module DataRail
  module Operation

    describe SaveRecord do

      let(:operation) { SaveRecord.new(logger: Logger.new(nil)) }
      let(:user) { User.create(ssn: '789', name: 'Jim', age: 32) }
      let(:result) { @result }

      before do
        user.name = 'Gymnasium'
        @result = operation.call(user)
      end

      describe 'user' do
        subject { user }

        its(:name) { should eq 'Gymnasium' }
        it { should be_persisted }
      end

      describe 'result' do
        subject { result }

        it { should eq user }
      end

      it 'should raise an error when the user isnt valid' do
        user.name = nil
        expect { operation.call(user) }.to raise_error(ActiveRecord::RecordInvalid)
      end

    end

  end
end