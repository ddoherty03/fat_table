# frozen_string_literal: true

module FatTable
  class Footer
    attr_reader :table, :label, :label_col, :values, :group

    ###########################################################################
    # Constructors
    ###########################################################################

    # :category: Constructors

    # Initialize a labeled footer, optionally specifying a column for the
    # label and whether the footer is to be a group footer. One or more values
    # for the footer are added later with the #add_value method.
    def initialize(label = 'Total', table, label_col: nil, group: false)
      @label = label
      unless table.is_a?(Table)
        raise ArgumentError, 'Footer.new needs a table argument'
      end
      if label_col.nil?
        @label_col = table.headers.first
      else
        unless table.headers.include?(label_col.as_sym)
          raise ArgumentError, "Footer.new label column '#{label_col}' not a header of table."
        end
        @label_col = label_col.as_sym
      end
      @table = table
      @group = group
      @group_cols = {}
      @values = {}
      if group
        @values[@label_col] = []
        table.number_of_groups.times do
          @values[@label_col] << @label
        end
      else
        @values[@label_col] = [@label]
      end
      make_accessor_methods
    end

    # :category: Constructors

    # Add a value to a footer for the footer's table at COL.  The value of the
    # footer is determined by AGG.  If it is a symbol, such as :sum or :avg,
    # it must be a valid aggregating function and the value is determined by
    # applying the aggregate to the columns in the table, or in a group
    # footer, to the rows in the group.  If AGG is not a symbol, but it can be
    # converted to a valid type for a FatTable::Table column, then it is so
    # converted and the value set to it directly without invoking an aggregate
    # function.
    def add_value(col, agg)
      col = col.as_sym
      if col.nil?
        raise ArgumentError, 'Footer#add_value col is nil but must name a table column.'
      else
        unless table.headers.include?(col.as_sym)
          raise ArgumentError, "Footer#add_value col '#{col}' not a header of the table."
        end
      end

      if group
        number_of_groups.times do |k|
          values[col] ||= []
          values[col] << calc_val(agg, col, k)
        end
      else
        values[col] = [calc_val(agg, col)]
      end
    end

    # :category: Accessors

    # Return the value of under the +key+ header, or if this is a group
    # footer, return an array of the values for all the groups under the +key+
    # header.
    def [](key)
      key = key.as_sym
      if values.keys.include?(key)
        if group
          values[key]
        else
          values[key].last
        end
      elsif table.headers.include?(label_col.as_sym)
        nil
      else
        raise ArgumentError, "No column header '#{key}' in footer table"
      end
    end

    # :category: Accessors

    # Return the total number of groups in the table to which this footer
    # belongs.  Note that if the table has both group footers and normal
    # footers, this will return the number of groups even for a normal footer.
    def number_of_groups
      table.number_of_groups
    end

    # :category: Accessors

    # Return a FatTable::Column object for the header h and, if a group, the
    # kth group.
    def column(h, k = nil)
      if group && k.nil?
        raise ArgumentError, 'Footer#column(h, k) missing the group number argument k'
      end
      if group
        k.nil? ? @group_cols[h] : @group_cols[h][k]
      else
        table.column(h)
      end
    end

    # :category: Accessors

    # Return an Array of the values for the header h and, if a group, for the
    # kth group.
    def items(h, k = nil)
      column(h, k).items
    end

    # :category: Accessors

    # Return a Hash with a key for each column header mapped to the footer
    # value for that column, nil for unused columns.  Use the key +k+ to
    # specify which group to access in the case of a group footer.
    def to_h(k = nil)
      hsh = {}
      if group
        table.headers.each do |h|
          hsh[h] = values[h] ? values[h][k] : nil
        end
      else
        table.headers.each do |h|
          hsh[h] =
            if values[h]
              values[h].first
            else
              nil
            end
        end
      end
      hsh
    end

    private

    # Evaluate the given agg for the header col and, in the case of a group
    # footer, the group k.
    def calc_val(agg, col, k = nil)
      column =
        if group
          @group_cols[col] ||= table.group_cols(col)
          @group_cols[col][k]
        else
          table.column(col)
        end

      case agg
      when Symbol
        column.send(agg)
      when String
        begin
          converted_val = Convert.convert_to_type(agg, column.type)
        rescue UserError, IncompatibleTypeError
          converted_val = false
        end
        if converted_val
          converted_val
        else
          agg
        end
      when column.type.constantize
        agg
      when Proc
        result =
          if group
            unless agg.arity == 3
              msg = 'a lambda used in a group footer must have three arguments: (f, c, k)'
              raise ArgumentError, msg
            end
            agg.call(self, col, k)
          else
            unless agg.arity == 2
              msg = 'a lambda used in a non-group footer must have two arguments: (f, c)'
              raise ArgumentError, msg
            end
            agg.call(self, col)
          end
        # Make sure the result returned can be inserted into footer field.
        case result
        when Symbol, String
          calc_val(result, col, k)
        when column.type.constantize
          result
        else
          raise ArgumentError, "lambda cannot return an object of class #{result.class}"
        end
      else
        agg
      end
    end

    # Define an accessor method for each table header that returns the footer
    # value for that column, and in the case of a group footer, either returns
    # the array of values or take an optional index k to return the value for
    # the k-th group.
    def make_accessor_methods
      table.headers.each do |attribute|
        self.class.define_method attribute do |k = nil|
          if group
            if k.nil?
              values[attribute]
            else
              values[attribute][k]
            end
          else
            values[attribute].last
          end
        end
      end
    end
  end
end
