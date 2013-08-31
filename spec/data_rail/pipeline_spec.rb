require 'data_rail/pipeline'

module DataRail
  describe Pipeline do

    class TestLogger

      def initialize
        @messages = []
      end

      attr_reader :messages

      def info(message)
        @messages << message
      end

      def has_message? message
        messages.include? message
      end

    end

    BRACKET = Proc.new do |value, logger|
      '[' + value + ']'
    end

    ANGLES = lambda { |value| "<" + value + ">" }

    LOGGER = lambda { |value, log| log.info "value=#{value}"; value }

    let(:components) { [BRACKET, ANGLES, LOGGER] }
    let(:pipeline) { Pipeline.new(components, logger) }
    let(:logger) { TestLogger.new }

    describe 'call' do
      let(:result) { pipeline.call 'apple' }
      subject { result }
      it { should eq '<[apple]>' }
    end

    describe 'process' do
      let(:result) { pipeline.process ['orange', 'banana'] }
      subject { result }
      its(:to_a) { should eq ['<[orange]>', '<[banana]>'] }
    end

    describe 'logger' do
      subject { logger }

      before { pipeline.call 'pear' }

      it { should have_message 'value=<[pear]>' }
    end

    describe '.build' do

      let(:pipeline) do
        Pipeline.build(logger) do
          use BRACKET
          use ANGLES
          use LOGGER
        end
      end

      describe 'process' do
        let(:result) { pipeline.process ['monkey', 'giraffe'] }
        subject { result }
        its(:to_a) { should eq ['<[monkey]>', '<[giraffe]>'] }
      end

    end

  end
end