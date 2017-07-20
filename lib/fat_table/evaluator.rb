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
    # Return a new Evaluator object in which the Hash +vars+ defines the
    # bindings for instance variables to be available and maintained across all
    # subsequent calls to Evaluator.evaluate. The strings +before+ and +after+
    # are string expressions that will be evaluated before and after each
    # subsequent call to Evaluator.evaluate.
    def initialize(ivars: {}, before: nil, after: nil)
      @before = before
      @after = after
      set_instance_vars(ivars)
    end

    # Run the before hook after setting the @group to grp, passed in as a
    # parameter.  This is run before any column has been evaluated with the
    # evaluate method.
    def eval_before_hook(vars)
      bdg = binding
      set_local_vars(vars, bdg)
      @group = vars[:__group]
      eval(@before, bdg) if @before
    end

    # Run the after hook.  This is run after each column in the row has been
    # evaluated with the evaluate method.
    def eval_after_hook(vars)
      bdg = binding
      set_local_vars(vars, bdg)
      eval(@after, bdg) if @after
    end

    # Return the result of evaluating +expr+ as a Ruby expression in which the
    # instance variables set in Evaluator.new and any local variables set in the
    # Hash parameter +vars+ are available to the expression.
    def evaluate(expr = '', vars: {})
      bdg = binding
      set_local_vars(vars, bdg)
      eval(expr, bdg)
    end

    private

    def set_instance_vars(vars = {})
      vars.each_pair do |name, val|
        name = "@#{name}" unless name.to_s.start_with?('@')
        instance_variable_set(name, val)
      end
    end

    def set_local_vars(vars = {}, bnd)
      vars.each_pair do |name, val|
        bnd.local_variable_set(name, val)
      end
    end
  end
end
