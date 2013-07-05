require 'data_rail/key'

module DataRail

  describe Key do
    let(:source) { 'abcd:53/defg:213' }
    let(:key) { Key.from_s(source) }
    subject { key }

    it 'should have the right components' do
      key[0, 0].should == 'abcd'
      key[0, 1].should == '53'
      key[1, 0].should == 'defg'
      key[1, 1].should == '213'
    end

    its(:to_s) { should eq 'abcd:53/defg:213' }

  end

end
