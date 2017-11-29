unless { a: 1 }.respond_to?(:fetch_values)
  # Add fetch_values if this version of ruby does not define it.
  class Hash
    def fetch_values(*keys)
      result = []
      keys.each do |k|
        result <<
          if block_given?
            yield(self[k])
          else
            self[k]
          end
      end
      result
    end
  end
end

unless ''.respond_to?(:match?)
  # Add String#match? to pre-2.4 ruby
  class String
    def match?(re)
      self =~ re
    end
  end
end

unless //.respond_to?(:match?)
  # Add Regexp#match? to pre-2.4 ruby
  class Regexp
    def match?(str)
      self =~ re
    end
  end
end
