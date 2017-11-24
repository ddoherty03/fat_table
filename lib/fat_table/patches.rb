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
