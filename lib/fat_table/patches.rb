# frozen_string_literal: true

unless { a: 1 }.respond_to?(:fetch_values)
  # Add fetch_values if this version of ruby does not define it.
  class Hash
    def fetch_values(*keys)
      keys.map do |k|
        if block_given?
          yield(self[k])
        else
          self[k]
        end
      end
    end
  end
end

unless ''.respond_to?(:match?)
  # Add String#match? to pre-2.4 ruby
  class String
    def match?(regexp)
      self =~ regexp
    end
  end
end

unless //.respond_to?(:match?)
  # Add Regexp#match? to pre-2.4 ruby
  class Regexp
    def match?(str)
      self =~ str
    end
  end
end

unless ''.respond_to?(:strip_heredoc)
  # Patch String to provide heredocs with whitespace stripped
  class String
    def strip_heredoc
      indent = chomp.scan(/^\s*/).min.size
      gsub(/^\s{#{indent}}/, '')
    end
  end
end
