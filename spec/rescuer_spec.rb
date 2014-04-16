require 'spec_helper'
require 'rescuer'

describe Rescuer do

  ##
  # Construction indirectly by wrapping a block which may raise
  ##
  describe '.new' do

    context 'when block does *not* raise' do
      subject { Rescuer.new { 1 + 1 } }
      it { is_expected.to eq(Rescuer::Success.new(2)) }
    end

    context 'when block raises and no arguments' do
      context 'when raise StandardError' do
        let(:e) { StandardError.new('a standard error') }
        subject { Rescuer.new { raise e } }
        it { is_expected.to eq(Rescuer::Failure.new(e)) }
      end

      context 'when raise NoMemoryError' do
        subject { lambda { Rescuer.new { raise NoMemoryError } } }
        it { is_expected.to raise_error(NoMemoryError) }
      end
    end

    context 'when block raises and Exception is an argument' do
      context 'when raise NoMemoryError' do
        let(:e) { NoMemoryError.new }
        subject { Rescuer.new(Exception) { raise e } }
        it { is_expected.to eq(Rescuer::Failure.new(e)) }
      end
    end

    context 'when block raises and two subclasses of Exception are arguments' do
      exceptions = [NoMemoryError, SyntaxError]

      context 'when raise StandardError' do
        subject { lambda { Rescuer.new(exceptions) { raise StandardError } } }
        it { is_expected.to raise_error(StandardError) }
      end

      context 'when raise SyntaxError' do
        let(:e) { SyntaxError.new }
        subject { Rescuer.new(Exception) { raise e } }
        it { is_expected.to eq(Rescuer::Failure.new(e)) }
      end

    end

    context 'when no block given' do
      subject { lambda { Rescuer.new } }
      it { is_expected.to raise_error(ArgumentError, 'no block given') }
    end

  end

  ##
  # Construction directly as Success
  ##
  describe Rescuer::Success do
    describe '.new' do
      context 'when any object' do
        subject { Rescuer::Success.new(42) }
        it { is_expected.to be_success }
        it { is_expected.to be_frozen }
      end
    end
  end

end
