require 'data_rail/adapted_collection'

module DataRail
  describe AdaptedCollection do

    class AdapterOne
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
      end

      def full_name
        "#{data_source.first_name} #{data_source.last_name}"
      end

      def signature
        "*#{data_source.signature}*"
      end
    end

    class AdapterTwo
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
      end

      def name
        data_source.full_name
      end

      def signature
        "<#{data_source.signature}>"
      end
    end

    let(:objects) { [double(first_name: 'John', last_name: 'Smith', signature: 'hi'),
                     double(first_name: 'Kate', last_name: 'Schmoe', signature: 'bye')] }
    let(:adapters) { nil }
    let(:collection) { AdaptedCollection.new(objects, adapters) }
    let(:results) { collection.to_a }

    context 'when no adapters are present' do
      it 'should leave the objects unchanged' do
        results.should == objects
      end
    end

    context 'when multiple adapters are present' do
      let(:adapters) { [AdapterOne, AdapterTwo] }
      it 'should wrap the objects properly' do
        results.map(&:name).should == ['John Smith', 'Kate Schmoe']
        results.map(&:signature).should == ['<*hi*>', '<*bye*>']
      end
    end

  end
end
