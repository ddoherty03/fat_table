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
        @group_cols[col] ||= table.group_cols(col)
        number_of_groups.times do |k|
          values[col] ||= []
          values[col] << calc_val(agg, @group_cols[col][k])
        end
      else
        val = calc_val(agg, table.column(col))
        values[col] = [val]
      end
    end

    def calc_val(agg, column)
      if agg.is_a?(Symbol)
        column.send(agg)
      elsif agg.is_a?(String)
        # TODO: allow eval of expression here.
        #
        # If it can be converted to the column type, convert it; otherwise if
        # it be evaled like a select clause, eval it; otherwise set it to the
        # string value.
        if (val = Convert.convert_to_type(agg, column.type))
          val
        else
          agg
        end
      elsif agg.is_a?(column.type)
        agg
      else
        raise ArgumentError, "Attempt to set footer column #{col} to '#{agg}' of type #{agg.class}"
      end
    end

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

    def number_of_groups
      return 1 unless group

      table.number_of_groups
    end

    # Return a Hash with a key for each column header mapped to the footer
    # value for that column, nil for unused columns.  Use the key +k+ to
    # specify which group to access in the case of a group footer.
    def to_hash(k = nil)
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
  end
end
