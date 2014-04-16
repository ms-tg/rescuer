require 'rescuer/version'

module Rescuer
  DEFAULT_EXCEPTIONS = [StandardError]

  def new(*exceptions)
    exceptions = DEFAULT_EXCEPTIONS if exceptions.nil? || exceptions.empty?
    Success.new(yield)
	rescue *exceptions => ex
    Failure.new(ex)
  end
  module_function :new

  Success = Struct.new(:value)
  Failure = Struct.new(:cause)
end