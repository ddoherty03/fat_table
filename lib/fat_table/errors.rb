module FatTable
  # Raised when the caller of the code made an error that the caller can
  # correct.
  class UserError < StandardError; end

  # Raised when the programmer made an error that the caller of the code
  # cannot correct.
  class LogicError < StandardError; end

  # Raised when an external resource is not available due to caller or
  # programmer error or some failure of the external resource to be available.
  class TransientError < StandardError; end
end
