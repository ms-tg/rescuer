require 'rescuer/version'

module Rescuer

  def new
    Success.new(yield)
	rescue => ex
    Failure.new(ex)
  end
  module_function :new

  Success = Struct.new(:value)
  Failure = Struct.new(:cause)
end