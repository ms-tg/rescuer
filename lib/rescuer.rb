require 'rescuer/version'

module Rescuer
  DEFAULT_EXCEPTIONS_TO_RESCUE = [StandardError]

  def new(*exceptions)
    raise ArgumentError, 'no block given' unless block_given?

    passed = exceptions && exceptions.flatten.compact
    to_rescue, to_pass =
      if passed.nil? || passed.empty? then [DEFAULT_EXCEPTIONS_TO_RESCUE, nil] else [passed, passed] end

    begin
      value = yield
      Success.new(value, to_pass)
	  rescue *to_rescue => error
      Failure.new(error, to_pass)
    end
  end
  module_function :new

  Success = Struct.new(:value, :exceptions_to_rescue) do
    def initialize(value, exceptions_to_rescue = nil)
      super(value, exceptions_to_rescue)
      freeze
    end

    def success?
      true
    end

    def failure?
      false
    end

    def get
      value
    end

    def get_or_else(_)
      value
    end

    def or_else(_)
      self
    end

    def failed
      Failure.new(TypeError.new('Success is not a Failure'))
    end

    def flat_map
      Rescuer.new(exceptions_to_rescue) { yield value }.flatten(1)
    end

    def map
      flat_map do |v|
        new_value = yield v
        Success.new(new_value)
      end
    end

    def each
      yield value
      self
    end

    def select
      flat_map do |v|
        predicate = yield v
        if predicate then self else Failure.new(IndexError.new("predicate does not hold for #{v}")) end
      end
    end
    alias_method :find_all, :select

    def transform(f_success, f_failure)
      flat_map { |v| f_success.call(v) }
    end

    def flatten(depth = nil)
      raise ArgumentError, 'invalid depth' unless depth.nil? || (depth.is_a?(Integer) && depth >= 0)
      if depth && depth.zero?
        self
      else
        case value
        when Success, Failure then value.flatten(depth && depth - 1)
        else self
        end
      end
    end
  end

  Failure = Struct.new(:exception, :exceptions_to_rescue) do
    def initialize(exception, exceptions_to_rescue = nil)
      super(exception, exceptions_to_rescue)
      raise ArgumentError, 'not an exception' unless exception.is_a? Exception
      freeze
    end

    def success?
      false
    end

    def failure?
      true
    end

    def get
      raise exception
    end

    def get_or_else(default)
      default
    end

    def or_else(other)
      other
    end

    def failed
      Success.new(exception)
    end

    def flat_map
      self
    end

    def map
      self
    end

    def each
      self
    end

    def transform(f_success, f_failure)
      failed.flat_map { |e| f_failure.call(e) }
    end

    def flatten(depth = nil)
      self
    end
  end
end