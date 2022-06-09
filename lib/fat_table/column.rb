# frozen_string_literal: true

module FatTable
  # Column objects are a thin wrapper around an Array to allow columns to be
  # summed and have other aggregate operations performed on them, but compacting
  # out nils before proceeding. They are characterized by a header, which gives
  # the Column a name, a type, which limits the kinds of items that can be
  # stored in the Column, and the items themselves, which all must either be nil
  # or objects compatible with the Column's type. The valid types are Boolean,
  # DateTime, Numeric, String, and NilClass, the last of which is used as the
  # initial type until items added to the Column fix its type as one of the
  # others.
  class Column
    # The symbol representing this Column.
    attr_reader :header

    # The header as provided by the caller before its conversion to a symbol.
    # You can use this to recover the original string form of the header.
    attr_reader :raw_header

    # A string representing the deduced type of this Column. One of
    # Column::TYPES.
    attr_reader :type

    # An Array of the items of this Column, all of which must be values of the
    # Column's type or a nil.  This Array contains the value of the item after
    # conversion to a native Ruby type, such as TrueClass, Date, DateTime,
    # Integer, String, etc.  Thus, you can perform operations on the items,
    # perhaps after removing nils with +.items.compact+.
    attr_reader :items

    # Valid Column types as strings.
    TYPES = %w[NilClass Boolean DateTime Numeric String].freeze

    # :category: Constructors

    # Create a new Column with the given +header+ and initialized with the given
    # +items+, as an array of either strings or ruby objects that are one of the
    # permissible types or strings parsable as one of the permissible types. If
    # no +items+ are passed, returns an empty Column to which items may be added
    # with the Column#<< method. The item types must be one of the following
    # types or strings parseable as one of them:
    #
    # Boolean::
    #     an object of type TrueClass or FalseClass or a string that is either
    #     't', 'true', 'y', 'yes', 'f', 'false', 'n', or 'no', in each case,
    #     regardless of case.
    #
    # DateTime::
    #      an object of class Date, DateTime, or a string that matches
    #      +/\d\d\d\d[-\/]\d\d?[-\/]\d\d?/+ and is parseable by DateTime.parse.
    #
    # Numeric:: on object that is of class Numeric, or a string that looks like
    #      a number after removing '+$+', '+,+', and '+_+' as well as Rationals
    #      in the form /<number>:<number>/ or <number>/<number>, where <number>
    #      is an integer.
    #
    # String::
    #      if the object is a non-blank string that does not parse as any
    #      of the foregoing, it its treated as a Sting type, and once a column
    #      is typed as such, blank strings represent blank strings rather than
    #      nil values.
    #
    # NilClass::
    #      until a Column sees an item that qualifies as one of the
    #      foregoing, it is typed as NilClass, meaning that the type is
    #      undetermined. Until a column obtains a type, blank strings are
    #      treated as nils and do not affect the type of the column. After a
    #      column acquires a type, blank strings are treated as nil values
    #      except in the case of String columns, which retain them a blank
    #      strings.
    #
    # Examples:
    #
    #   require 'fat_table'
    #   col = FatTable::Column.new(header: 'date')
    #   col << Date.today - 30
    #   col << '2017-05-04'
    #   col.type #=> 'DateTime'
    #   col.header #=> :date
    #   nums = [35.25, 18, '35:14', '$18_321']
    #   col = FatTable::Column.new(header: :prices, items: nums)
    #   col.type #=> 'Numeric'
    #   col.header #=> :prices
    #   col.sum #=> 18376.75
    def initialize(header:, items: [], type: 'NilClass', tolerant: false)
      @raw_header = header
      @header =
        if @raw_header.is_a?(Symbol)
          @raw_header
        else
          @raw_header.to_s.as_sym
        end
      @type = type
      @tolerant = tolerant
      msg = "unknown column type '#{type}"
      raise UserError, msg unless TYPES.include?(@type.to_s)

      @items = []
      items.each { |i| self << i }
    end

    ##########################################################################
    # Attributes
    ##########################################################################

    # :category: Attributes

    # Return the item of the Column at the given index.
    def [](idx)
      items[idx]
    end

    # :category: Attributes

    # Return a dupped Array of this Column's items. To get the non-dupped items,
    # just use the .items accessor.
    def to_a
      items.deep_dup
    end

    # :category: Attributes

    # Return the size of the Column, including any nils.
    def size
      items.size
    end

    # :category: Attributes

    # Return true if there are no items in the Column.
    def empty?
      items.empty?
    end

    # :category: Attributes

    # Return the index of the last item in the Column.
    def last_i
      size - 1
    end

    # :category: Attributes

    # Is this column tolerant of type incompatibilities?  If so, the Column
    # type will be forced to String if an incompatible type is found.
    def tolerant?
      @tolerant
    end

    # :category: Attributes

    # Force the column to have String type and then convert all items to
    # strings.
    def force_string!
      @type = 'String'
      unless empty?
        @items = items.map(&:to_s)
      end
    end

    ##########################################################################
    # Enumerable
    ##########################################################################

    include Enumerable

    # :category: Attributes

    # Yield each item in the Column in the order in which they appear in the
    # Column. This makes Columns Enumerable, so all the Enumerable methods are
    # available on a Column.
    def each
      if block_given?
        items.each { |itm| yield itm }
        self
      else
        to_enum(:each)
      end
    end

    ##########################################################################
    # Aggregates
    ##########################################################################

    # :category: Aggregates

    # The names of the known aggregate operations that can be performed on a
    # Column.
    VALID_AGGREGATES = %s(first last range
                          sum count min max
                          avg var pvar dev pdev
                          any? all? none? one?)

    # :category: Aggregates

    # Return the first non-nil item in the Column, or nil if all items are
    # nil.  Works with any Column type.
    def first
      return nil if items.all?(&:nil?)

      if type == 'String'
        items.reject(&:blank?).first
      else
        items.filter_to_type(type).first
      end
    end

    # :category: Aggregates

    # Return the last non-nil item in the Column.  Works with any Column type.
    def last
      return nil if items.all?(&:nil?)

      if type == 'String'
        items.reject(&:blank?).last
      else
        items.filter_to_type(type).last
      end
    end

    # :category: Aggregates

    # Return a count of the non-nil items in the Column, or the size of the
    # column if all items are nil.  Works with any Column type.
    def count
      return items.size if items.all?(&:nil?)

      if type == 'String'
        items.reject(&:blank?).count.to_d
      else
        items.filter_to_type(type).count.to_d
      end
    end

    # :category: Aggregates

    # Return the smallest non-nil, non-blank item in the Column, or nil if all
    # items are nil.  Works with numeric, string, and datetime Columns.
    def min
      only_with('min', 'NilClass', 'Numeric', 'String', 'DateTime')
      if type == 'String'
        items.reject(&:blank?).min
      else
        items.filter_to_type(type).min
      end
    end

    # :category: Aggregates

    # Return the largest non-nil, non-blank item in the Column, or nil if all
    # items are nil.  Works with numeric, string, and datetime Columns.
    def max
      only_with('max', 'NilClass', 'Numeric', 'String', 'DateTime')
      if type == 'String'
        items.reject(&:blank?).max
      else
        items.filter_to_type(type).max
      end
    end

    # :category: Aggregates

    # Return a Range object for the smallest to largest value in the column,
    # or nil if all items are nil.  Works with numeric, string, and datetime
    # Columns.
    def range
      only_with('range', 'NilClass', 'Numeric', 'String', 'DateTime')
      return nil if items.all?(&:nil?)

      Range.new(min, max)
    end

    # :category: Aggregates

    # Return the sum of the non-nil items in the Column, or 0 if all items are
    # nil.  Works with numeric and string Columns. For a string Column, it
    # will return the concatenation of the non-nil items.
    def sum
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('sum', 'Numeric', 'String')
      if type == 'String'
        items.reject(&:blank?).join(' ')
      else
        items.filter_to_type(type).sum
      end
    end

    # :category: Aggregates

    # Return the average value of the non-nil items in the Column, or 0 if all
    # items are nil.  Works with numeric and datetime Columns.  For datetime
    # Columns, it converts each date to its Julian day number, computes the
    # average, and then converts the average back to a DateTime.
    def avg
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('avg', 'DateTime', 'Numeric')
      itms = items.filter_to_type(type)
      size = itms.size.to_d
      if type == 'DateTime'
        avg_jd = itms.map(&:jd).sum / size
        DateTime.jd(avg_jd)
      else
        itms.sum / size
      end
    end

    # :category: Aggregates

    # Return the sample variance (the unbiased estimator of the population
    # variance using a divisor of N-1) as the average squared deviation from
    # the mean, of the non-nil items in the Column, or 0 if all items are
    # nil. Works with numeric and datetime Columns. For datetime Columns, it
    # converts each date to its Julian day number and computes the variance of
    # those numbers.
    def var
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('var', 'DateTime', 'Numeric')
      all_items =
        if type == 'DateTime'
          items.filter_to_type(type).map(&:jd)
        else
          items.filter_to_type(type)
        end
      n = count
      return BigDecimal('0.0') if n <= 1
      mu = Column.new(header: :mu, items: all_items).avg
      sq_dev = BigDecimal('0.0')
      all_items.each do |itm|
        sq_dev += (itm - mu) * (itm - mu)
      end
      sq_dev / (n - 1)
    end

    # :category: Aggregates

    # Return the population variance (the biased estimator of the population
    # variance using a divisor of N) as the average squared deviation from the
    # mean, of the non-nil items in the Column, or 0 if all items are
    # nil. Works with numeric and datetime Columns. For datetime Columns, it
    # converts each date to its Julian day number and computes the variance of
    # those numbers.
    def pvar
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('var', 'DateTime', 'Numeric')
      n = items.filter_to_type(type).size.to_d
      return BigDecimal('0.0') if n <= 1
      var * ((n - 1) / n)
    end

    # :category: Aggregates

    # Return the sample standard deviation (the unbiased estimator of the
    # population standard deviation using a divisor of N-1) as the square root
    # of the sample variance, of the non-nil items in the Column, or 0 if all
    # items are nil. Works with numeric and datetime Columns. For datetime
    # Columns, it converts each date to its Julian day number and computes the
    # standard deviation of those numbers.
    def dev
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('dev', 'DateTime', 'Numeric')
      var.sqrt(20)
    end

    # :category: Aggregates

    # Return the population standard deviation (the biased estimator of the
    # population standard deviation using a divisor of N) as the square root
    # of the population variance, of the non-nil items in the Column, or 0 if
    # all items are nil. Works with numeric and datetime Columns. For datetime
    # Columns, it converts each date to its Julian day number and computes the
    # standard deviation of those numbers.
    def pdev
      return 0 if type == 'NilClass' || items.all?(&:nil?)

      only_with('dev', 'DateTime', 'Numeric')
      Math.sqrt(pvar)
    end

    # :category: Aggregates

    # Return true if any of the items in the Column are true; otherwise return
    # false, or false if all items are nil.  Works only with boolean Columns.
    def any?
      return false if type == 'NilClass' || items.all?(&:nil?)

      only_with('any?', 'Boolean')
      items.filter_to_type(type).any?
    end

    # :category: Aggregates

    # Return true if all of the items in the Column are true; otherwise return
    # false, or false if all items are nil.  Works only with boolean Columns.
    def all?
      return false if type == 'NilClass' || items.all?(&:nil?)

      only_with('all?', 'Boolean')
      items.filter_to_type(type).all?
    end

    # :category: Aggregates

    # Return true if none of the items in the Column are true; otherwise
    # return false, or true if all items are nil.  Works only with boolean
    # Columns.
    def none?
      return true if type == 'NilClass' || items.all?(&:nil?)

      only_with('none?', 'Boolean')
      items.filter_to_type(type).none?
    end

    # :category: Aggregates

    # Return true if precisely one of the items in the Column is true;
    # otherwise return false.  Works only with boolean Columns.
    def one?
      return false if type == 'NilClass' || items.all?(&:nil?)

      only_with('one?', 'Boolean')
      items.filter_to_type(type).one?
    end

    private

    def only_with(agg, *valid_types)
      return self if valid_types.include?(type)

      msg = "aggregate '#{agg}' cannot be applied to a #{type} column"
      raise UserError, msg
    end

    public

    ##########################################################################
    # Construction
    ##########################################################################

    # :category: Constructors

    # Append +itm+ to end of the Column after converting it to the Column's
    # type. If the Column's type is still open, i.e. NilClass, attempt to fix
    # the Column's type based on the type of +itm+ as with Column.new.  If its
    # a tolerant column, respond to type errors by converting the column to a
    # String type.
    def <<(itm)
      items << convert_and_set_type(itm)
    rescue IncompatibleTypeError => ex
      if tolerant?
        items << Convert.convert_to_string(itm)
      else
        raise ex
      end
    end

    # :category: Constructors

    # Return a new Column appending the items of other to this Column's items,
    # checking for type compatibility.  Use the header of this Column as the
    # header of the new Column.
    def +(other)
      msg = 'cannot combine columns with different types'
      raise UserError, msg unless type == other.type
      Column.new(header: header, items: items + other.items)
    end

    private

    def convert_and_set_type(val)
      begin
        new_val = Convert.convert_to_type(val, type, tolerant: tolerant?)
      rescue IncompatibleTypeError
        err_msg = "attempt to add '#{val}' to column '#{header}' already typed as #{type}"
        raise IncompatibleTypeError, err_msg
      end
      if new_val && (type == 'NilClass' || type == 'String')
        @type =
          if [true, false].include?(new_val)
            'Boolean'
          elsif new_val.is_a?(Date) || new_val.is_a?(DateTime)
            'DateTime'
          elsif new_val.is_a?(Numeric)
            'Numeric'
          elsif new_val.is_a?(String)
            'String'
          else
            msg = "can't add value '#{val}' of type #{new_val.class.name} to a column"
            raise UserError, msg
          end
      end
      new_val
    end
  end
end
