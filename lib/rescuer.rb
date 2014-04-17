require 'rescuer/version'

module Rescuer
  DEFAULT_EXCEPTIONS_TO_RESCUE = [StandardError]

  def new(*exceptions_to_rescue)
    exceptions_to_rescue = DEFAULT_EXCEPTIONS_TO_RESCUE if exceptions_to_rescue.nil? || exceptions_to_rescue.empty?
    raise ArgumentError, 'no block given' unless block_given?
    begin
      Success.new(yield)
	  rescue *exceptions_to_rescue => ex
      Failure.new(ex)
    end
  end
  module_function :new

  Success = Struct.new(:value) do
    def initialize(value)
      super(value)
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

  Failure = Struct.new(:exception) do
    def initialize(exception)
      super(exception)
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

    def flatten(depth = nil)
      self
    end
  end
end