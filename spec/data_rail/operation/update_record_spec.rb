require 'spec_helper'

require 'data_rail/operation/update_record'
require 'hashie/mash'

module DataRail
  module Operation

    describe UpdateRecord do

      KEY = lambda { |o| o.attributes[:ssn] }

      context 'the record is new' do

        let(:attributes) do
          Hashie::Mash.new(
              ssn: '123',
              name: 'John',
              age: 42,
              anniversary: Time.utc(2013, 10, 6)
          )
        end

        let(:object) { Hashie::Mash.new(attributes: attributes.clone) }

        let(:operation) { UpdateRecord.new(User, fields: {key: KEY}) }

        let(:user) { operation.call(object) }

        describe 'John' do
          subject { user }

          its(:ssn) { should eq '123' }
          its(:name) { should eq 'John' }
          its(:age) { should eq 42 }
          its(:anniversary) { should eq Time.utc(2013, 10, 6) }

          it { should_not be_persisted }
        end

      end

    end

  end
end