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
   def initialize(vars: {}, before: nil, after: nil)
     @before = before
     @after = after
     set_instance_vars(vars)
   end

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

   def evaluate(expr = '', vars: {})
     bdg = binding
     set_local_vars(vars, bdg)
     eval(@before, bdg) if @before
     result = eval(expr, bdg)
     eval(@after, bdg) if @after
     result
   end
  end
end
