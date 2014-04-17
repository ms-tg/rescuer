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
    context 'when given any object' do
      let(:the_value) { 42 }
      let(:a_success) { Rescuer::Success.new(the_value) }

      describe '.new' do
        subject { a_success }
        it { is_expected.to     be_frozen }
        it { is_expected.to     be_success }
        it { is_expected.not_to be_failure }
        it { is_expected.to     respond_to :value }
        it { is_expected.not_to respond_to :exception }
      end

      describe '#value' do
        subject { a_success.value }
        it { is_expected.to be the_value}
      end

      describe '#get' do
        subject { a_success.get }
        it { is_expected.to be the_value }
      end
    end
  end

  ##
  # Construction directly as Failure
  ##
  describe Rescuer::Failure do
    context 'when given an exception' do
      let(:the_error) { StandardError.new('a standard error') }
      let(:a_failure) { Rescuer::Failure.new(the_error) }

      describe '.new' do
        subject { a_failure }
        it { is_expected.to     be_frozen }
        it { is_expected.not_to be_success }
        it { is_expected.to     be_failure }
        it { is_expected.not_to respond_to :value }
        it { is_expected.to     respond_to :exception }
      end

      describe '#exception' do
        subject { a_failure.exception }
        it { is_expected.to be the_error }
      end

      describe '#get' do
        subject { lambda { a_failure.get } }
        it { is_expected.to raise_error(the_error) }
      end
    end

    context 'when given a *non*-exception' do
      describe '.new' do
        subject { lambda { Rescuer::Failure.new(42) } }
        it { is_expected.to raise_error(ArgumentError, 'not an exception') }
      end
    end
  end

end
