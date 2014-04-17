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
  end
end