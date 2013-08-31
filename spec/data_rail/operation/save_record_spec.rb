require 'spec_helper'

require 'data_rail/operation/save_record'
require 'hashie/mash'

module DataRail
  module Operation

    describe SaveRecord do

      let(:operation) { SaveRecord.new }
      let(:user) { User.create(ssn: '789', name: 'Jim', age: 32) }

      before do
        user.name = 'Gymnasium'
        operation.call(user)
      end

      describe 'user' do
        subject { user }

        its(:name) { should eq 'Gymnasium' }
        it { should be_persisted }
      end

    end

  end
end