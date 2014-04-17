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
  end

  Failure = Struct.new(:exception) do
    def initialize(value)
      super(value)
      raise ArgumentError, 'not an exception' unless value.is_a? Exception
      freeze
    end

    def success?
      false
    end

    def failure?
      true
    end
  end
end