# frozen_string_literal: true

module FatTable
  # The Evaluator class provides a class for evaluating Ruby expressions based
  # on variable settings provided at runtime. If the same Evaluator object is
  # used for several successive calls, it can maintain state between calls with
  # instance variables. The call to Evaluator.new can be given a hash of
  # instance variable names and values that will be maintained across all calls
  # to the #evaluate method. In addition, on each evaluate call, a set of
  # /local/ variables can be supplied to provide variables that exist only for
  # the duration of that evaluate call. An optional before and after string can
  # be given to the constructor that will evaluate the given expression before
  # and, respectively, after each call to #evaluate. This provides a way to
  # update values of instance variables for use in subsequent calls to
  # #evaluate.
  class Evaluator
    # Return a new Evaluator object in which the Hash +ivars+ defines the
    # bindings for instance variables to be available and maintained across all
    # subsequent calls to Evaluator.evaluate. The strings +before+ and +after+
    # are string Ruby expressions that will be evaluated before and after each
    # subsequent call to Evaluator.evaluate.
    def initialize(ivars: {}, before: nil, after: nil)
      @before = before
      @after = after
      instance_vars(ivars)
    end

    # Set the @group instance variable to the given value.
    def update_ivars(ivars)
      instance_vars(ivars)
    end

    # Run any before hook in the context of the given local variables.
    def eval_before_hook(locals: {})
      return if @before.blank?

      evaluate(@before, locals: locals)
    end

    # Run any after hook in the context of the given local variables.
    def eval_after_hook(locals: {})
      return if @after.blank?

      evaluate(@after, locals: locals)
    end

    # Return the result of evaluating +expr+ as a Ruby expression in which the
    # instance variables set in Evaluator.new and any local variables set in
    # the Hash parameter +locals+ are available to the expression.  Certain
    # errors simply return nil as the result.  This can happen, for example,
    # when a string gets into an otherwise numeric column because the column
    # is set to tolerant.
    #
    # rubocop:disable  Security/Eval
    def evaluate(expr = '', locals: {})
      eval(expr, local_vars(binding, locals))
    rescue NoMethodError, TypeError
      nil
    end
    # rubocop:enable  Security/Eval

    private

    # Set the instance variables according to Hash vars.
    def instance_vars(vars = {})
      vars.each_pair do |name, val|
        name = "@#{name}" unless name.to_s.start_with?('@')
        instance_variable_set(name, val)
      end
    end

    # Set the local variables within the binding bnd according to Hash vars.
    def local_vars(bnd, vars = {})
      vars.each_pair do |name, val|
        bnd.local_variable_set(name, val)
      end
      bnd
    end
  end
end
