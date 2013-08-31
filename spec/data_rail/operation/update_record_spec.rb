require 'pry'

require 'spec_helper'

require 'data_rail/operation/update_record'
require 'hashie/mash'

module DataRail
  module Operation

    describe UpdateRecord do

      KEY = lambda { |o| o.attributes[:ssn] }

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

      context 'when the record is new' do

        describe 'user' do
          subject { user }

          its(:key) { should eq '123' }
          its(:ssn) { should eq '123' }
          its(:name) { should eq 'John' }
          its(:age) { should eq 42 }
          its(:anniversary) { should eq Time.utc(2013, 10, 6) }

          it { should_not be_persisted }
        end

      end

      context 'when the record already exists' do
        before do
          User.create(key: '456', ssn: '456', name: 'Kevin', age: 42, anniversary: Time.utc(2013, 10, 12))
        end

        let(:attributes) do
          Hashie::Mash.new(
              ssn: '456',
              name: 'Jose'
          )
        end

        describe 'user' do
          subject { user }

          its(:key) { should eq '456' }
          its(:ssn) { should eq '456' }
          its(:name) { should eq 'Jose' }
          its(:age) { should eq 42 }
          its(:anniversary) { should eq Time.utc(2013, 10, 12) }

          it { should be_persisted }
        end
      end

    end

  end
end