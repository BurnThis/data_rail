require 'data_rail/adapter'

module DataRail
  class TestAdapter
    include Virtus
    include Adapter

    field :id, Integer, :from => :id
    field :name, String, :from => :first_name
    field :zip, String, :from => 'address.zip_code'
    field :price, Float, :from => 'charge.amount_in_cents'
    field :test_name, String, :from => 'test.name'
    field :stripthis, String, :from => 'unstripped', :process => [:strip]
    field :newid, Integer, :from => 'id', :process => lambda { |id| id.to_i + 5 }

    def initialize(data_source)
      super
    end

  end

  describe Adapter do
    context 'when creating a new class' do
      let(:data_source) do
        {
          :id => '3',
          :first_name => 'mr bob',
          :last_name => 'smith',
          :address => {zip_code: '21108'},
          :charge => double(type: 'stripe', amount_in_cents: 2350),
          :test => {'name' => 'abc'},
          :unstripped => '  abc def '
        }
      end

      let(:adapter) { TestAdapter.new(data_source) }
      subject { adapter }

      its(:id) { should eq 3 }
      its(:name) { should eq 'mr bob' }
      its(:zip) { should eq '21108' }
      its(:price) { should eq 2350 }
      its(:test_name) { should eq 'abc' }

      its(:stripthis) { should eq 'abc def' }
      its(:newid) { should eq 8 }

    end

    context 'when there is a dead-end property' do
      let(:data_source) do
        {
          :test => nil
        }
      end

      let(:adapter) { TestAdapter.new(data_source) }
      subject { adapter }

      its(:test_name) { should be_nil }

    end

  end

end
