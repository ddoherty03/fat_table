module FatTable
  # Raised when the caller of the code made an error that the call can correct.
  class UserError < StandardError; end

  # Raised when the programmer made an error that the caller of the code
  # cannot correct.
  class LogicError < StandardError; end

  # Raised when an external resource is not available not due to caller or
  # programmer error.
  class TransientError < StandardError; end
end
