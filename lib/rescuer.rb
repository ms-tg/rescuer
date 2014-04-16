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

  Success = Struct.new(:value)
  Failure = Struct.new(:cause)
end