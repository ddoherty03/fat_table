module FatTable
  # Column objects are just a thin wrapper around an Array to allow columns to
  # be summed and have other operations performed on them, but compacting out
  # nils before proceeding. My original attempt to do this by monkey-patching
  # Array turned out badly.  This works much nicer.
  class Column
    attr_reader :header, :raw_header, :type, :items

    TYPES = %w(NilClass Boolean DateTime Numeric String).freeze

    def initialize(header:, items: [])
      @raw_header = header
      @header =
        if @raw_header.is_a?(Symbol)
          @raw_header
        else
          @raw_header.as_sym
        end
      @type = 'NilClass'
      raise UserError, "Unknown column type '#{type}" unless TYPES.include?(@type.to_s)
      @items = []
      items.each { |i| self << i }
    end

    ##########################################################################
    # Attributes
    ##########################################################################

    # Return the item of the column at the given index.
    def [](k)
      items[k]
    end

    # Convert the column to an Array.
    def to_a
      items
    end

    # Return the size of the column, including any nils.
    def size
      items.size
    end

    # Return true if there are no items in the column.
    def empty?
      items.empty?
    end

    # Return the index of the last item in the column.
    def last_i
      size - 1
    end

    ##########################################################################
    # Enumerable
    ##########################################################################

    include Enumerable

    def each
      items.each { |itm| yield itm }
    end

    ##########################################################################
    # Aggregates
    ##########################################################################

    VALID_AGGREGATES = %s(first last rng
                          sum count min max avg var dev
                          any? all? none? one?)

    # Return the first non-nil item in the column.  Works with any column type.
    def first
      items.compact.first
    end

    # Return the last non-nil item in the column.  Works with any column type.
    def last
      items.compact.last
    end

    # Return a string of the first and last non-nil values.  Works with any
    # column type.
    def rng
      "#{first}..#{last}"
    end

    # Return the sum of the non-nil items in the column.  Works with numeric and
    # string columns. For a string column, it will return the concatenation of
    # the non-nil items.
    def sum
      only_with('sum', 'Numeric', 'String')
      items.compact.sum
    end

    # Return a count of the non-nil items in the column.  Works with any column
    # type.
    def count
      items.compact.count
    end

    # Return the smallest non-nil item in the column.  Works with numeric,
    # string, and datetime columns.
    def min
      only_with('min', 'NilClass', 'Numeric', 'String', 'DateTime')
      items.compact.min
    end

    # Return the largest non-nil item in the column.  Works with numeric,
    # string, and datetime columns.
    def max
      only_with('max', 'NilClass', 'Numeric', 'String', 'DateTime')
      items.compact.max
    end

    # Return the average value of the non-nil items in the column.  Works with
    # numeric and datetime columns.  For datetime columns, it converts each date
    # to its Julian day number, computes the average, and then converts the
    # average back to a DateTime.
    def avg
      only_with('avg', 'DateTime', 'Numeric')
      if type == 'DateTime'
        avg_jd = items.compact.map(&:jd).sum / items.compact.size.to_d
        DateTime.jd(avg_jd)
      else
        sum / items.compact.size.to_d
      end
    end

    # Return the variance, the average squared deviation from the mean, of the
    # non-nil items in the column.  Works with numeric and datetime columns.
    # For datetime columns, it converts each date to its Julian day number and
    # computes the variance of those numbers.
    def var
      only_with('var', 'DateTime', 'Numeric')
      all_items =
        if type == 'DateTime'
          items.compact.map(&:jd)
        else
          items.compact
        end
      mu = Column.new(header: :mu, items: all_items).avg
      sq_dev = 0.0
      all_items.compact.each do |itm|
        sq_dev += (itm - mu) * (itm - mu)
      end
      sq_dev / items.compact.size.to_d
    end

    # Return the standard deviation, the square root of the variance, of the
    # non-nil items in the column.  Works with numeric and datetime columns.
    # For datetime columns, it converts each date to its Julian day number and
    # computes the standard deviation of those numbers.
    def dev
      only_with('dev', 'DateTime', 'Numeric')
      Math.sqrt(var)
    end

    # Return true if any of the items in the column are true; otherwise return
    # false.  Works only with boolean columns.
    def any?
      only_with('any?', 'Boolean')
      items.compact.any?
    end

    # Return true if all of the items in the column are true; otherwise return
    # false.  Works only with boolean columns.
    def all?
      only_with('all?', 'Boolean')
      items.compact.all?
    end

    # Return true if none of the items in the column are true; otherwise return
    # false.  Works only with boolean columns.
    def none?
      only_with('any?', 'Boolean')
      items.compact.none?
    end

    # Return true if precisely one of the items in the column is true;
    # otherwise return false.  Works only with boolean columns.
    def one?
      only_with('any?', 'Boolean')
      items.compact.one?
    end

    private

    def only_with(agg, *valid_types)
      return self if valid_types.include?(type)
      raise UserError, "Aggregate '#{agg}' cannot be applied to a #{type} column"
    end

    public

    ##########################################################################
    # Construction
    ##########################################################################

    # Append item to end of the column
    def <<(itm)
      items << convert_to_type(itm)
    end

    # Return a new Column appending the items of other to our items, checking
    # for type compatibility.
    def +(other)
      raise UserError, 'Cannot combine columns with different types' unless type == other.type
      Column.new(header: header, items: items + other.items)
    end

    private

    # Convert val to the type of key, a ruby class constant, such as Date,
    # Numeric, etc. If type is NilClass, the type is open, and a non-blank val
    # will attempt conversion to one of the allowed types, typing it as a String
    # if no other type is recognized. If the val is blank, and the type is nil,
    # the column type remains open. If the val is nil or a blank and the type is
    # already determined, the val is set to nil, and should be filtered from any
    # column computations. If the val is non-blank and the column type
    # determined, raise an error if the val cannot be converted to the column
    # type. Otherwise, returns the converted val as an object of the correct
    # class.
    def convert_to_type(val)
      case type
      when 'NilClass'
        if val != false && val.blank?
          # Leave the type of the column open. Unfortunately, false counts as
          # blank and we don't want it to. It should be classified as a boolean.
          new_val = nil
        else
          # Only non-blank values are allowed to set the type of the column
          bool_val = convert_to_boolean(val)
          new_val =
            if bool_val.nil?
              convert_to_date_time(val) ||
                convert_to_numeric(val) ||
                convert_to_string(val)
            else
              bool_val
            end
          @type =
            if new_val == true || new_val == false
              'Boolean'
            elsif new_val.is_a?(Date) || new_val.is_a?(DateTime)
              'DateTime'
            elsif new_val.is_a?(Numeric)
              'Numeric'
            elsif new_val.is_a?(String)
              'String'
            else
              raise UserError, "Cannot add #{val} of type #{new_val.class.name} to a column"
            end
        end
        new_val
      when 'Boolean'
        if (val.is_a?(String) && val.blank? || val.nil?)
          nil
        else
          new_val = convert_to_boolean(val)
          if new_val.nil?
            raise UserError, "Attempt to add '#{val}' to a column already typed as #{type}"
          end
          new_val
        end
      when 'DateTime'
        if val.blank?
          nil
        else
          new_val = convert_to_date_time(val)
          if new_val.nil?
            raise UserError, "Attempt to add '#{val}' to a column already typed as #{type}"
          end
          new_val
        end
      when 'Numeric'
        if val.blank?
          nil
        else
          new_val = convert_to_numeric(val)
          if new_val.nil?
            raise UserError, "Attempt to add '#{val}' to a column already typed as #{type}"
          end
          new_val
        end
      when 'String'
        if val.nil?
          nil
        else
          new_val = convert_to_string(val)
          if new_val.nil?
            raise UserError, "Attempt to add '#{val}' to a column already typed as #{type}"
          end
          new_val
        end
      else
        raise UserError, "Mysteriously, column has unknown type '#{type}'"
      end
    end

    # Convert the val to a boolean if it looks like one, otherwise return nil.
    # Any boolean or a string of t, f, true, false, y, n, yes, or no, regardless
    # of case is assumed to be a boolean.
    def convert_to_boolean(val)
      return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)
      val = val.to_s.clean
      return nil if val.blank?
      if val =~ /\A(false|f|n|no)\z/i
        false
      elsif val =~ /\A(true|t|y|yes)\z/i
        true
      end
    end

    # Convert the val to a DateTime if it is either a DateTime, a Date, or a
    # String that can be parsed as a DateTime, otherwise return nil. It only
    # recognizes strings that contain a something like '2016-01-14' or
    # '2/12/1985' within them, otherwise DateTime.parse would treat many bare
    # numbers as dates, such as '2841381', which it would recognize as a valid
    # date, but the user probably does not intend it to be so treated.
    def convert_to_date_time(val)
      return val if val.is_a?(DateTime)
      return val if val.is_a?(Date)
      begin
        val = val.to_s.clean
        return nil if val.blank?
        return nil unless val =~ %r{\b\d\d\d\d[-/]\d\d?[-/]\d\d?\b}
        val = DateTime.parse(val.to_s.clean)
        val = val.to_date if val.seconds_since_midnight.zero?
        val
      rescue ArgumentError
        return nil
      end
    end

    # Convert the val to a Numeric if is already a Numberic or is a String that
    # looks like one. Any Float is promoted to a BigDecimal. Otherwise return
    # nil.
    def convert_to_numeric(val)
      return BigDecimal.new(val, Float::DIG) if val.is_a?(Float)
      return val if val.is_a?(Numeric)
      # Eliminate any commas, $'s, or _'s.
      val = val.to_s.clean.gsub(/[,_$]/, '')
      return nil if val.blank?
      case val
      when /\A(\d+\.\d*)|(\d*\.\d+)\z/
        BigDecimal.new(val.to_s.clean)
      when /\A[\d]+\z/
        val.to_i
      when %r{\A(\d+)\s*[:/]\s*(\d+)\z}
        Rational($1, $2)
      end
    end

    def convert_to_string(val)
      val.to_s
    end
  end
end
