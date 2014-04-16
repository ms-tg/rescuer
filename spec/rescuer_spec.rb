require 'spec_helper'
require 'rescuer'

describe Rescuer do

  describe '.new' do

    context 'when block does *not* raise' do
      subject { Rescuer.new { 1 + 1 } }
      it { is_expected.to eq(Rescuer::Success.new(2)) }
    end

    context 'when no arguments and block raises' do

      context 'when raise StandardError' do
        let(:e) { StandardError.new('a standard error') }
        subject { Rescuer.new { raise e } }
        it { is_expected.to eq(Rescuer::Failure.new(e)) }
      end

    end

  end

end
