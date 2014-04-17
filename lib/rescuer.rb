require 'rescuer/version'

module Rescuer
  DEFAULT_EXCEPTIONS = [StandardError]

  def new(*exceptions)
    exceptions = DEFAULT_EXCEPTIONS if exceptions.nil? || exceptions.empty?
    raise ArgumentError, 'no block given' unless block_given?
    begin
      Success.new(yield)
	  rescue *exceptions => ex
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