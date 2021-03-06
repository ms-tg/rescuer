require 'spec_helper'
require 'rescuer'

describe Rescuer do

  ##
  # Construct indirectly by wrapping a block which may raise an exception
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
        it { is_expected.to eq(Rescuer::Failure.new(e, [Exception])) }
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
        subject { Rescuer.new(exceptions) { raise e } }
        it { is_expected.to eq(Rescuer::Failure.new(e, exceptions)) }
      end

    end

    context 'when no block given' do
      subject { lambda { Rescuer.new } }
      it { is_expected.to raise_error(ArgumentError, 'no block given') }
    end

  end

  ##
  # Construct directly as Success
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
        it { is_expected.to     respond_to :exceptions_to_rescue }
        it { is_expected.not_to respond_to :exception }
      end

      describe '#==, #eql?, #equal?, #hash' do
        subject { a_success }
        let(:another) { Rescuer::Success.new(the_value) }
        it { is_expected.to          eq    another }
        it { is_expected.to          eql   another }
        it { is_expected.not_to      equal another }
        it { expect(subject.hash).to eq    another.hash }
      end

      describe '#value' do
        subject { a_success.value }
        it { is_expected.to be the_value}
      end

      describe '#exceptions_to_rescue' do
        context 'when not given' do
          subject { a_success.exceptions_to_rescue }
          it { is_expected.to be_nil }
        end

        context 'when given' do
          let(:ex_to_rescue) { [ArgumentError, TypeError] }
          subject { Rescuer::Success.new(the_value, ex_to_rescue).exceptions_to_rescue }
          it { is_expected.to be ex_to_rescue }
        end
      end

      describe '#get' do
        subject { a_success.get }
        it { is_expected.to be the_value }
      end

      describe '#get_or_else' do
        subject { a_success.get_or_else(123) }
        it { is_expected.to be the_value }
      end

      describe '#or_else' do
        let(:another) { Rescuer::Success.new(123) }
        subject { a_success.or_else(another) }
        it { is_expected.to be a_success }
      end

      describe '#failed' do
        subject { a_success.failed }
        it { is_expected.to               be_instance_of Rescuer::Failure }
        it { expect(subject.exception).to eq             TypeError.new('Success is not a Failure') }
      end

      describe '#each' do
        context 'when block does *not* raise' do
          let(:acc) { arr = []; a_success.each { |v| arr << v }; arr }
          subject { dummy = []; a_success.each { |v| dummy << v } }
          it { is_expected.to be a_success }
          it { expect(acc).to eq [the_value] }
        end

        context 'when block raises' do
          let(:the_error) { StandardError.new('a standard error') }
          subject { lambda { a_success.each { |_| raise the_error } } }
          it { is_expected.to raise_error(the_error) }
        end
      end

      describe '#map' do
        let(:to_rescue) { [ArgumentError] }
        let(:a_success_rescuing_ae) { Rescuer::Success.new(the_value, to_rescue) }

        context 'when block returns a value' do
          subject { a_success.map { |v| v + 1 } }
          it { is_expected.to eq Rescuer::Success.new(the_value + 1) }
        end

        context 'when block raises an exception that is to be rescued' do
          let(:the_error) { ArgumentError.new('an error to be rescued') }
          subject { a_success_rescuing_ae.map { |_| raise the_error } }
          it { is_expected.to eq Rescuer::Failure.new(the_error, to_rescue) }
        end

        context 'when block raises an exception that is *not* to be rescued' do
          let(:the_error) { StandardError.new('a standard error') }
          subject { lambda { a_success_rescuing_ae.map { |_| raise the_error } } }
          it { is_expected.to raise_error(the_error) }
        end
      end

      describe '#flat_map' do
        let(:to_rescue) { [ArgumentError] }
        let(:a_success_rescuing_ae) { Rescuer::Success.new(the_value, to_rescue) }

        context 'when block returns a Success' do
          subject { a_success.flat_map { |v| Rescuer::Success.new(v + 1) } }
          it { is_expected.to eq Rescuer::Success.new(the_value + 1) }
        end

        context 'when block raises an exception that is to be rescued' do
          let(:the_error) { ArgumentError.new('an error to be rescued') }
          subject { a_success_rescuing_ae.flat_map { |_| raise the_error } }
          it { is_expected.to eq Rescuer::Failure.new(the_error, to_rescue) }
        end

        context 'when block raises an exception that is *not* to be rescued' do
          let(:the_error) { StandardError.new('a standard error') }
          subject { lambda { a_success_rescuing_ae.flat_map { |_| raise the_error } } }
          it { is_expected.to raise_error(the_error) }
        end
      end

      shared_examples 'select methods' do
        context 'when predicate returns true' do
          subject { select_method { |v| v == the_value } }
          it { is_expected.to be a_success }
        end

        context 'when predicate returns false' do
          let(:the_error) { IndexError.new('predicate does not hold for 42') }
          subject { select_method { |v| v != the_value } }
          it { is_expected.to eq Rescuer::Failure.new(the_error) }
        end

        context 'when predicate raises an exception that is to be rescued' do
          let(:the_error) { StandardError.new('a standard error') }
          subject { select_method { |_| raise the_error } }
          it { is_expected.to eq Rescuer::Failure.new(the_error) }
        end

        context 'when predicate raises an exception that is *not* to be rescued' do
          subject { lambda { select_method { |_| raise NoMemoryError } } }
          it { is_expected.to raise_error(NoMemoryError) }
        end
      end

      describe '#select' do
        def select_method; a_success.select { |v| yield v }; end
        it_behaves_like 'select methods'
      end

      describe '#find_all' do
        def select_method; a_success.find_all { |v| yield v }; end
        it_behaves_like 'select methods'
      end

      describe '#transform' do
        subject { a_success.transform(lambda { |v| Rescuer::Success.new(v + 1) },
                                      lambda { |e| Rescuer::Success.new(e.message.length) }) }
        it { is_expected.to eq Rescuer::Success.new(the_value + 1) }
      end

      describe '#flatten' do
        let(:nested_once)  { Rescuer::Success.new(a_success)   }
        let(:nested_twice) { Rescuer::Success.new(nested_once) }
        let(:nested_fail)  { Rescuer::Success.new(Rescuer::Failure.new(StandardError.new('a standard error'))) }

        context 'given an invalid depth' do
          let(:string_depth)   { lambda { a_success.flatten('hey!') } }
          let(:negative_depth) { lambda { a_success.flatten(-1)     } }
          let(:float_depth)    { lambda { a_success.flatten(1.23)   } }
          it { expect(string_depth).to   raise_error(ArgumentError, 'invalid depth') }
          it { expect(negative_depth).to raise_error(ArgumentError, 'invalid depth') }
          it { expect(float_depth).to    raise_error(ArgumentError, 'invalid depth') }
        end

        context 'when *not* nested' do
          context 'given depth is nil' do
            subject { a_success.flatten }
            it { is_expected.to be a_success }
          end

          context 'given depth = 1' do
            subject { a_success.flatten(1) }
            it { is_expected.to be a_success }
          end
        end

        context 'when nested success containing success' do
          context 'given depth is nil' do
            subject { nested_once.flatten }
            it { is_expected.to be a_success }
          end

          context 'given depth = 1' do
            subject { nested_once.flatten(1) }
            it { is_expected.to be a_success }
          end
        end

        context 'when nested success containing success containing success' do
          context 'given depth is nil' do
            subject { nested_twice.flatten }
            it { is_expected.to be a_success }
          end

          context 'given depth = 1' do
            subject { nested_twice.flatten(1) }
            it { is_expected.to be nested_once }
          end
        end

        context 'when nested success containing failure' do
          context 'given depth is nil' do
            subject { nested_fail.flatten }
            it { is_expected.to be nested_fail.value }
          end

          context 'given depth = 1' do
            subject { nested_fail.flatten(1) }
            it { is_expected.to be nested_fail.value }
          end
        end
      end
    end
  end

  ##
  # Construct directly as Failure
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

      describe '#==, #eql?, #equal?, #hash' do
        subject { a_failure }
        let(:another) { Rescuer::Failure.new(the_error) }
        it { is_expected.to          eq    another }
        it { is_expected.to          eql   another }
        it { is_expected.not_to      equal another }
        it { expect(subject.hash).to eq    another.hash }
      end

      describe '#exception' do
        subject { a_failure.exception }
        it { is_expected.to be the_error }
      end

      describe '#exceptions_to_rescue' do
        context 'when not given' do
          subject { a_failure.exceptions_to_rescue }
          it { is_expected.to be_nil }
        end

        context 'when given' do
          let(:ex_to_rescue) { [ArgumentError, TypeError] }
          subject { Rescuer::Failure.new(the_error, ex_to_rescue).exceptions_to_rescue }
          it { is_expected.to be ex_to_rescue }
        end
      end

      describe '#get' do
        subject { lambda { a_failure.get } }
        it { is_expected.to raise_error(the_error) }
      end

      describe '#get_or_else' do
        subject { a_failure.get_or_else(123) }
        it { is_expected.to be 123 }
      end

      describe '#or_else' do
        let(:another) { Rescuer::Success.new(123) }
        subject { a_failure.or_else(another) }
        it { is_expected.to be another }
      end

      describe '#failed' do
        subject { a_failure.failed }
        it { is_expected.to           be_instance_of Rescuer::Success }
        it { expect(subject.value).to be             the_error }
      end

      describe '#each' do
        let(:acc) { arr = []; a_failure.each { |v| arr << v }; arr }
        subject { dummy = []; a_failure.each { |v| dummy << v } }
        it { is_expected.to be a_failure }
        it { expect(acc).to eq [] }
      end

      describe '#map' do
        subject { a_failure.map { |v| v + 1 } }
        it { is_expected.to be a_failure }
      end

      describe '#flat_map' do
        subject { a_failure.flat_map { |v| Rescuer::Success.new(v + 1) } }
        it { is_expected.to be a_failure }
      end

      shared_examples 'select methods' do
        context 'when predicate returns true' do
          subject { select_method { |v| v == the_value } }
          it { is_expected.to be a_failure }
        end

        context 'when predicate returns false' do
          subject { select_method { |v| v != the_value } }
          it { is_expected.to be a_failure }
        end

        context 'when predicate raises any exception' do
          subject { select_method { |_| raise the_error } }
          it { is_expected.to be a_failure }
        end
      end

      describe '#select' do
        def select_method; a_failure.select { |v| yield v }; end
        it_behaves_like 'select methods'
      end

      describe '#find_all' do
        def select_method; a_failure.find_all { |v| yield v }; end
        it_behaves_like 'select methods'
      end

      describe '#transform' do
        subject { a_failure.transform(lambda { |v| Rescuer::Success.new(v + 1) },
                                      lambda { |e| Rescuer::Success.new(e.message.length) }) }
        it { is_expected.to eq Rescuer::Success.new(the_error.message.length) }
      end

      describe '#flatten' do
        context 'given depth is nil' do
          subject { a_failure.flatten }
          it { is_expected.to be a_failure }
        end

        context 'given depth = 1' do
          subject { a_failure.flatten(1) }
          it { is_expected.to be a_failure }
        end
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
