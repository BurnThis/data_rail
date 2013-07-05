require 'data_rail/adaptable'

module DataRail


  Wrapper = Struct.new(:data_source) do
    def name
      '<' + data_source.name + '>'
    end
  end

  Thing = Struct.new(:name)

  class ThingCollection
    include DataRail::Adaptable

    def each
      yield Thing.new('a')
      yield Thing.new('b')
    end
  end

  describe Adaptable do
    context 'when adapting a collection' do
      let(:collection) { ThingCollection.new.adapt(Wrapper) }

      it 'should have the adapted items' do
        collection.map(&:name).should == ['<a>', '<b>']
      end
    end
  end

end
