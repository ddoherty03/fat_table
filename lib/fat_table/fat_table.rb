module FatCore
  # A container for a two-dimensional table. All cells in the table must be a
  # String, a DateTime (or Date), a Numeric (Bignum, Integer, or BigDecimal), or
  # a Boolean (TrueClass or FalseClass). All columns must be of one of those
  # types or be a string convertible into one of them. It is considered an error
  # if a single column contains cells of different types. Any cell that cannot
  # be parsed as one of the Numeric, DateTime, or Boolean types will be treated
  # as a String and have to_s applied.  Until the column type is determined, it
  # will have the type NilClass.
  #
  # You can initialize a Table in several ways:
  #
  # 1. with a Nil, which will return an empty table to which rows or columns can
  #    be added later, 2. with the name of a .csv file, 3. with the name of an
  #    .org file, 4. with an IO or StringIO object for either type of file, but
  #    in that case, you need to specify 'csv' or 'org' as the second argument
  #    to tell it what kind of file format to expect, 5. with an Array of
  #    Arrays, 6. with an Array of Hashes, all having the same keys, which
  #    become the names of the column heads, 7. with an Array of any objects
  #    that respond to .keys and .values methods, 8. with another Table object.
  #
  # In the resulting Table, the headers are converted into symbols, with all
  # spaces converted to underscore and everything down-cased. So, the heading,
  # 'Two Words' becomes the hash header :two_words.
  class Table
    attr_reader :columns

    def initialize
      @columns = []
      @boundaries = []
    end

    ###########################################################################
    # Constructors
    ###########################################################################

    # Construct a Table from the contents of a CSV file.  Headers will be taken
    # from the first row and converted to symbols.
    def self.from_csv_file(fname)
      File.open(fname, 'r') do |io|
        from_csv_io(io)
      end
    end

    # Construct a Table from a string, treated as the input from a CSV file.
    def self.from_csv_string(str)
      from_csv_io(StringIO.new(str))
    end

    # Construct a Table from the first table found in the given org-mode file.
    # Headers are taken from the first row if the second row is an hrule.``
    def self.from_org_file(fname)
      File.open(fname, 'r') do |io|
        from_org_io(io)
      end
    end

    # Construct a Table from a string, treated as the contents of an org-mode
    # file.
    def self.from_org_string(str)
      from_org_io(StringIO.new(str))
    end

    # Construct a Table from an array of arrays.  If the second element is a nil
    # or is an array whose first element is a string that looks like a rule
    # separator, '|-----------', '+----------', etc., the headers will be taken
    # from the first array converted to strings and then to symbols.  Any
    # following such rows mark a group boundary.  Note that this is the form of
    # a table used by org-mode src blocks, so it is useful for building Tables
    # from the result of a src block.
    def self.from_aoa(aoa)
      from_array_of_arrays(aoa)
    end

    # Construct a Table from an array of hashes, or any objects that respond to
    # the #to_h method.  All hashes must have the same keys, which, when
    # converted to symbols will become the headers for the Table.
    def self.from_aoh(aoh)
      if aoh.first.respond_to?(:to_h)
        from_array_of_hashes(aoh)
      else
        raise ArgumentError,
              "Cannot initialize Table with an array of #{input[0].class}"
      end
    end

    # Construct a Table from another Table.  Inherit any group boundaries from
    # the input table.
    def self.from_table(table)
      from_aoh(table.rows)
      @boundaries = table.boundaries
    end

    ############################################################################
    # Class-level constructor helpers
    ############################################################################

    class << self
      private

      # Construct table from an array of hashes or an array of any object that can
      # respond to #to_h.  If an array element is a nil, mark it as a group
      # boundary in the Table.
      def from_array_of_hashes(hashes)
        result = new
        hashes.each do |hsh|
          if hsh.nil?
            result.mark_boundary
            next
          end
          result << hsh.to_h
        end
        result
      end

      # Construct a new table from an array of arrays. If the second element of
      # the array is a nil, a string that looks like an hrule, or an array whose
      # first element is a string that looks like an hrule, interpret the first
      # element of the array as a row of headers. Otherwise, synthesize headers of
      # the form "col1", "col2", ... and so forth. The remaining elements are
      # taken as the body of the table, except that if an element of the outer
      # array is a nil or a string that looks like an hrule, mark the preceding
      # row as a boundary.
      def from_array_of_arrays(rows)
        result = new
        headers = []
        if looks_like_boundary?(rows[1])
          # Take the first row as headers
          # Use first row 0 as headers
          headers = rows[0].map(&:as_sym)
          first_data_row = 2
        else
          # Synthesize headers
          headers = (1..rows[0].size).to_a.map { |k| "col#{k}".as_sym }
          first_data_row = 0
        end
        rows[first_data_row..-1].each do |row|
          if looks_like_boundary?(row)
            result.mark_boundary
            next
          end
          row = row.map { |s| s.to_s.strip }
          hash_row = Hash[headers.zip(row)]
          result << hash_row
        end
        result
      end

      # Return true if row is nil, a string that matches hrule_re, or is an
      # array whose first element matches hrule_re.
      def looks_like_boundary?(row)
        hrule_re = /\A\s*[\|+][-]+/
        return true if row.nil?
        if row.respond_to?(:first) && row.first.respond_to?(:to_s)
          return row.first.to_s =~ hrule_re
        end
        if row.respond_to?(:to_s)
          return row.to_s =~ hrule_re
        end
        false
      end

      def from_csv_io(io)
        result = new
        ::CSV.new(io, headers: true, header_converters: :symbol,
                  skip_blanks: true).each do |row|
          result << row.to_h
        end
        result
      end

      # Form rows of table by reading the first table found in the org file.
      def from_org_io(io)
        table_re = /\A\s*\|/
        hrule_re = /\A\s*\|[-+]+/
        rows = []
        table_found = false
        header_found = false
        io.each do |line|
          unless table_found
            # Skip through the file until a table is found
            next unless line =~ table_re
            unless line =~ hrule_re
              line = line.sub(/\A\s*\|/, '').sub(/\|\s*\z/, '')
              rows << line.split('|').map(&:clean)
            end
            table_found = true
            next
          end
          break unless line =~ table_re
          if !header_found && line =~ hrule_re
            rows << nil
            header_found = true
            next
          elsif header_found && line =~ hrule_re
            # Mark the boundary with a nil
            rows << nil
          elsif line !~ table_re
            # Stop reading at the second hline
            break
          else
            line = line.sub(/\A\s*\|/, '').sub(/\|\s*\z/, '')
            rows << line.split('|').map(&:clean)
          end
        end
        from_array_of_arrays(rows)
      end
    end

    ###########################################################################
    # Attributes
    ###########################################################################

    # Return the column with the given header.
    def column(key)
      columns.detect { |c| c.header == key.as_sym }
    end

    # Return the type of the column with the given header
    def type(key)
      column(key).type
    end

    # Return the array of items of the column with the given header, or if the
    # index is an integer, return that row number.  So a table's rows can be
    # accessed by number, and its columns can be accessed by column header.
    # Also, double indexing works in either row-major or column-majoir order:
    # tab[:id][8] returns the 8th item in the column headed :id and so does
    # tab[8][:id].
    def [](key)
      case key
      when Integer
        raise "index '#{key}' out of range" unless (1..size).cover?(key)
        rows[key - 1]
      when String
        raise "header '#{key}' not in table" unless headers.include?(key)
        column(key).items
      when Symbol
        raise "header ':#{key}' not in table" unless headers.include?(key)
        column(key).items
      else
        raise "cannot index table with a #{key.class}"
      end
    end

    # Return true if the table has a column with the given header.
    def column?(key)
      headers.include?(key.as_sym)
    end

    # Return an array of the Table's column types.
    def types
      columns.map(&:type)
    end

    # Return the headers for the Table as an array of symbols.
    def headers
      columns.map(&:header)
    end

    # Return the number of rows in the Table.
    def size
      return 0 if columns.empty?
      columns.first.size
    end

    # Return whether this Table is empty.
    def empty?
      size.zero?
    end

    # Return the rows of the Table as an array of hashes, keyed by the headers.
    def rows
      rows = []
      unless columns.empty?
        0.upto(columns.first.items.last_i) do |rnum|
          row = {}
          columns.each do |col|
            row[col.header] = col[rnum]
          end
          rows << row
        end
      end
      rows
    end

    protected

    # Return the rows from first to last.  We could just index #rows, but in a
    # large table, that would require that we construct all the rows for a range
    # of any size.
    def rows_range(first = 0, last = size - 1)
      raise ArgumentError, 'first must be <= last' unless first <= last
      rows = []
      unless columns.empty?
        first.upto(last) do |rnum|
          row = {}
          columns.each do |col|
            row[col.header] = col[rnum]
          end
          rows << row
        end
      end
      rows
    end

    ## ###########################################################################
    ##  Group Boundaries
    ##
    ##  Boundaries mark the last row in each "group" within the table. The last
    ##  row of the table is always an implicit boundary, and having the last row
    ##  as the sole boundary is the default for new tables unless mentioned
    ##  otherwise. Resetting the boundaries means to put it back in that default
    ##  state.
    ##
    ##  Note that tables are for the most part, immutable. That is, the data
    ##  rows of the table, once set, are never changed by methods on the
    ##  table. Any transformation of a table results in a new table. Boundaries
    ##  and footers are exceptions to immutability, but even they only affect
    ##  the boundary and footer attributes of the table, not the data rows.
    ##
    ##  Boundaries can be added when a table is read in, for example, from the
    ##  text of an org table in which each hline (other than the one separating
    ##  the headers from the body) marks a boundary for the row immediately
    ##  preceding the hline.
    ##
    ##  The #order_by method resets the boundaries then adds boundaries at the
    ##  last row of each group of rows on which the sort keys were equal as a
    ##  boundary.
    ##
    ##  The #union_all (but not #union since it deletes duplicates) method adds
    ##  a boundary between the constituent tables. #union_all also preserves any
    ##  boundary markers within the constituent tables. In doing so, the
    ##  boundaries of the second table in the #union_all are increased by the
    ##  size of the first table so that they refer to rows in the new table.
    ##
    ##  The #select method preserves any boundaries from the parent table
    ##  without change, since it only selects columns for the output and deletes
    ##  no rows.
    ##
    ##  Perhaps surprisingly, the #group_by method does /not/ result in any
    ##  groups in the output table since the result of #group_by is to reduce
    ##  all groups it finds into a single row, and having a group for each row
    ##  of the output table would have no use.
    ##
    ##  All the other table-transforming methods reset the boundaries in the new
    ##  table. For example, #where re-arranges and deletes rows, so the old
    ##  boundaries would make no sense anyway. Likewise, #union, #intersection,
    ##  #except, and #join reset the boundaries to their default.
    ##  ###########################################################################

    public

    # Return an array of an array of row hashes for the groups in this Table.
    def groups
      normalize_boundaries
      groups = []
      (0..boundaries.size - 1).each do |k|
        groups << group_rows(k)
      end
      groups
    end

    # Mark a boundary at k, and if k is nil, the last row in the table
    # as a group boundary.
    def mark_boundary(k = nil)
      if k
        boundaries.push(k)
      else
        boundaries.push(size - 1)
      end
    end

    protected

    # Reader for boundaries, but not public.
    def boundaries
      @boundaries
    end

    # Writer for boundaries, but not public.
    def boundaries=(bounds)
      @boundaries = bounds
    end

    # Make sure size - 1 is last boundary and that they are unique and sorted.
    def normalize_boundaries
      unless empty?
        boundaries.push(size - 1) unless boundaries.include?(size - 1)
        self.boundaries = boundaries.uniq.sort
      end
      boundaries
    end

    # Concatenate the array of argument bounds to this table's boundaries, but
    # increase each of the indexes in bounds by shift. This is used in the
    # #union_all method.
    def append_boundaries(bounds, shift: 0)
      @boundaries += bounds.map { |k| k + shift }
    end

    # Return the group number to which row k belongs. Groups, from the user's
    # point of view are indexed starting at 1.
    def row_index_to_group_index(k)
      boundaries.each_with_index do |b_last, g_num|
        return (g_num + 1) if k <= b_last
      end
      1
    end

    def group_rows(k)
      normalize_boundaries
      return [] unless k < boundaries.size
      first = k.zero? ? 0 : boundaries[k - 1] + 1
      last = boundaries[k]
      rows_range(first, last)
    end

    ############################################################################
    # SQL look-alikes. The following methods are based on SQL equivalents and
    # all return a new Table object rather than modifying the table in place.
    ############################################################################

    public

    # Return a new Table sorting the rows of this Table on the possibly multiple
    # keys given in the array of syms in headers. Append a ! to the symbol name
    # to indicate reverse sorting on that column. Resets groups.
    def order_by(*sort_heads)
      sort_heads = [sort_heads].flatten
      rev_heads = sort_heads.select { |h| h.to_s.ends_with?('!') }
      sort_heads = sort_heads.map { |h| h.to_s.sub(/\!\z/, '').to_sym }
      rev_heads = rev_heads.map { |h| h.to_s.sub(/\!\z/, '').to_sym }
      new_rows = rows.sort do |r1, r2|
        key1 = sort_heads.map { |h| rev_heads.include?(h) ? r2[h] : r1[h] }
        key2 = sort_heads.map { |h| rev_heads.include?(h) ? r1[h] : r2[h] }
        key1 <=> key2
      end
      # Add the new rows to the table, but mark a group boundary at the points
      # where the sort key changes value.
      new_tab = Table.new
      last_key = nil
      new_rows.each_with_index do |nrow, k|
        new_tab << nrow
        key = nrow.fetch_values(*sort_heads)
        new_tab.mark_boundary(k - 1) if last_key && key != last_key
        last_key = key
      end
      new_tab.normalize_boundaries
      new_tab
    end

    # Return a Table having the selected column expressions. Each expression can
    # be either a (1) symbol, :old_col, representing a column in the current
    # table, (2) a hash of new_col: :old_col to rename an existing :old_col
    # column as :new_col, or (3) a hash of new_col: 'expression', to add a new
    # column that is computed as an arbitrary ruby expression of the existing
    # columns (whether selected for the output table or not) or any new_col
    # defined earlier in the argument list.  The expression string can also
    # access the instance variable @row as the row number of the row being
    # evaluated.  The bare symbol arguments (1) must precede any hash arguments
    # (2) or (3). Each expression results in a column in the resulting Table in
    # the order given. The expressions are evaluated in left-to-right order as
    # well.  The output table preserves any groups present in the input table.
    def select(*cols, **new_cols)
      result = Table.new
      normalize_boundaries
      ev = Evaluator.new(vars: { row: 0, group: 1 },
                         before: '@row = __row; @group = __group')
      rows.each_with_index do |old_row, old_k|
        new_row = {}
        cols.each do |k|
          h = k.as_sym
          raise "Column '#{h}' in select does not exist" unless column?(h)
          new_row[h] = old_row[h]
        end
        new_cols.each_pair do |key, val|
          key = key.as_sym
          vars = old_row.merge(new_row)
          vars[:__row] = old_k + 1
          vars[:__group] = row_index_to_group_index(old_k)
          case val
          when Symbol
            raise "Column '#{val}' in select does not exist" unless vars.keys.include?(val)
            new_row[key] = vars[val]
          when String
            new_row[key] = ev.evaluate(val, vars: vars)
          else
            raise 'Hash parameters to select must be a symbol or string'
          end
        end
        result << new_row
      end
      result.boundaries = boundaries
      result.normalize_boundaries
      result
    end

    # Return a Table containing only rows matching the where expression.  Resets
    # groups.
    def where(expr)
      expr = expr.to_s
      result = Table.new
      ev = Evaluator.new(vars: { row: 0 },
                         before: '@row = __row; @group = __group')
      rows.each_with_index do |row, k|
        vars = row
        vars[:__row] = k + 1
        vars[:__group] = row_index_to_group_index(k)
        result << row if ev.evaluate(expr, vars: row)
      end
      result.normalize_boundaries
      result
    end

    # Return this table with all duplicate rows eliminated. Resets groups.
    def distinct
      result = Table.new
      uniq_rows = rows.uniq
      uniq_rows.each do |row|
        result << row
      end
      result
    end

    # Return this table with all duplicate rows eliminated. Resets groups.
    def uniq
      distinct
    end

    # Return a Table that combines this table with another table. In other
    # words, return the union of this table with the other. The headers of this
    # table are used in the result. There must be the same number of columns of
    # the same type in the two tables, or an exception will be thrown.
    # Duplicates are eliminated from the result.
    def union(other)
      set_operation(other, :+,
                    distinct: true,
                    add_boundaries: true)
    end

    # Return a Table that combines this table with another table. In other
    # words, return the union of this table with the other. The headers of this
    # table are used in the result. There must be the same number of columns of
    # the same type in the two tables, or an exception will be thrown.
    # Duplicates are not eliminated from the result.  Adds group boundaries at
    # boundaries of the constituent tables. Preserves and adjusts the group
    # boundaries of the constituent table.
    def union_all(other)
      set_operation(other, :+,
                    distinct: false,
                    add_boundaries: true,
                    inherit_boundaries: true)
    end

    # Return a Table that includes the rows that appear in this table and in
    # another table. In other words, return the intersection of this table with
    # the other. The headers of this table are used in the result. There must be
    # the same number of columns of the same type in the two tables, or an
    # exception will be thrown. Duplicates are eliminated from the
    # result. Resets groups.
    def intersect(other)
      set_operation(other, :intersect, true)
    end

    # Return a Table that includes the rows that appear in this table and in
    # another table. In other words, return the intersection of this table with
    # the other. The headers of this table are used in the result. There must be
    # the same number of columns of the same type in the two tables, or an
    # exception will be thrown. Duplicates are not eliminated from the
    # result. Resets groups.
    def intersect_all(other)
      set_operation(other, :intersect, false)
    end

    # Return a Table that includes the rows of this table except for any rows
    # that are the same as those in another table. In other words, return the
    # set difference between this table an the other. The headers of this table
    # are used in the result. There must be the same number of columns of the
    # same type in the two tables, or an exception will be thrown. Duplicates
    # are eliminated from the result. Resets groups.
    def except(other)
      set_operation(other, :difference, true)
    end

    # Return a Table that includes the rows of this table except for any rows
    # that are the same as those in another table. In other words, return the
    # set difference between this table an the other. The headers of this table
    # are used in the result. There must be the same number of columns of the
    # same type in the two tables, or an exception will be thrown. Duplicates
    # are not eliminated from the result. Resets groups.
    def except_all(other)
      set_operation(other, :difference, false)
    end

    private

    # Apply the set operation given by op between this table and the other table
    # given in the first argument.  If distinct is true, eliminate duplicates
    # from the result.
    def set_operation(other, op = :+,
                      distinct: true,
                      add_boundaries: false,
                      inherit_boundaries: false)
      unless columns.size == other.columns.size
        raise 'Cannot apply a set operation to tables with a different number of columns.'
      end
      unless columns.map(&:type) == other.columns.map(&:type)
        raise 'Cannot apply a set operation to tables with different column types.'
      end
      other_rows = other.rows.map { |r| r.replace_keys(headers) }
      result = Table.new
      new_rows = rows.send(op, other_rows)
      new_rows.each_with_index do |row, k|
        result << row
        result.mark_boundary if k == size - 1 && add_boundaries
      end
      if inherit_boundaries
        result.boundaries = normalize_boundaries
        other.normalize_boundaries
        result.append_boundaries(other.boundaries, shift: size)
      end
      result.normalize_boundaries
      distinct ? result.distinct : result
    end

    public

    # Return a table that joins this table to another based on one or more join
    # expressions. There are several possibilities for the join expressions:
    #
    # 1. If no join expressions are given, the tables will be joined when all
    #    values with the same name in both tables have the same value, a
    #    "natural" join. However, if the join type is :cross, the join
    #    expression will be taken to be 'true'. Otherwise, if there are no
    #    common column names, an exception will be raised.
    #
    # 2. If the join expressions are one or more symbols, the join condition
    #    requires that the values of both tables are equal for all columns named
    #    by the symbols. A column that appears in both tables can be given
    #    without modification and will be assumed to require equality on that
    #    column. If an unmodified symbol is not a name that appears in both
    #    tables, an exception will be raised. Column names that are unique to
    #    the first table must have a '_a' appended to the column name and column
    #    names that are unique to the other table must have a '_b' appended to
    #    the column name. These disambiguated column names must come in pairs,
    #    one for the first table and one for the second, and they will imply a
    #    join condition that the columns must be equal on those columns. Several
    #    such symbol expressions will require that all such implied pairs are
    #    equal in order for the join condition to be met.
    #
    # 3. Finally, a string expression can be given that contains an arbitrary
    #    ruby expression that will be evaluated for truthiness. Within the
    #    string, all column names must be disambiguated with the '_a' or '_b'
    #    modifiers whether they are common to both tables or not.  The names of
    #    the columns in both tables (without the leading ':' for symbols) are
    #    available as variables within the expression.
    #
    # The join_type parameter specifies what sort of join is performed, :inner,
    # :left, :right, :full, or :cross. The default is an :inner join. The types
    # of joins are defined as follows where T1 means this table, the receiver,
    # and T2 means other. These descriptions are taken from the Postgresql
    # documentation.
    #
    # - :inner :: For each row R1 of T1, the joined table has a row for each row
    #      in T2 that satisfies the join condition with R1.
    #
    # - :left :: First, an inner join is performed. Then, for each row in T1
    #      that does not satisfy the join condition with any row in T2, a joined
    #      row is added with null values in columns of T2. Thus, the joined
    #      table always has at least one row for each row in T1.
    #
    # - :right :: First, an inner join is performed. Then, for each row in T2
    #      that does not satisfy the join condition with any row in T1, a joined
    #      row is added with null values in columns of T1. This is the converse
    #      of a left join: the result table will always have a row for each row
    #      in T2.
    #
    # - :full :: First, an inner join is performed. Then, for each row in T1
    #      that does not satisfy the join condition with any row in T2, a joined
    #      row is added with null values in columns of T2. Also, for each row of
    #      T2 that does not satisfy the join condition with any row in T1, a
    #      joined row with null values in the columns of T1 is added.
    #
    # -  :cross :: For every possible combination of rows from T1 and T2 (i.e.,
    #      a Cartesian product), the joined table will contain a row consisting
    #      of all columns in T1 followed by all columns in T2. If the tables
    #      have N and M rows respectively, the joined table will have N * M
    #      rows.
    # Resets groups.
    JOIN_TYPES = [:inner, :left, :right, :full, :cross].freeze

    def join(other, *exps, join_type: :inner)
      unless other.is_a?(Table)
        raise ArgumentError, 'need other table as first argument to join'
      end
      unless JOIN_TYPES.include?(join_type)
        raise ArgumentError, "join_type may only be: #{JOIN_TYPES.join(', ')}"
      end
      # These may be needed for outer joins.
      self_row_nils = headers.map { |h| [h, nil] }.to_h
      other_row_nils = other.headers.map { |h| [h, nil] }.to_h
      join_expression, other_common_heads = build_join_expression(exps, other, join_type)
      ev = Evaluator.new
      result = Table.new
      other_rows = other.rows
      other_row_matches = Array.new(other_rows.size, false)
      rows.each do |self_row|
        self_row_matched = false
        other_rows.each_with_index do |other_row, k|
          # Same as other_row, but with keys that are common with self and equal
          # in value, removed, so the output table need not repeat them.
          locals = build_locals_hash(row_a: self_row, row_b: other_row)
          matches = ev.evaluate(join_expression, vars: locals)
          next unless matches
          self_row_matched = other_row_matches[k] = true
          out_row = build_out_row(row_a: self_row, row_b: other_row,
                                  common_heads: other_common_heads,
                                  type: join_type)
          result << out_row
        end
        if join_type == :left || join_type == :full
          unless self_row_matched
            out_row = build_out_row(row_a: self_row, row_b: other_row_nils, type: join_type)
            result << out_row
          end
        end
      end
      if join_type == :right || join_type == :full
        other_rows.each_with_index do |other_row, k|
          unless other_row_matches[k]
            out_row = build_out_row(row_a: self_row_nils, row_b: other_row, type: join_type)
            result << out_row
          end
        end
      end
      result.normalize_boundaries
      result
    end

    def inner_join(other, *exps)
      join(other, *exps)
    end

    def left_join(other, *exps)
      join(other, *exps, join_type: :left)
    end

    def right_join(other, *exps)
      join(other, *exps, join_type: :right)
    end

    def full_join(other, *exps)
      join(other, *exps, join_type: :full)
    end

    def cross_join(other)
      join(other, join_type: :cross)
    end

    private

    # Return an output row appropriate to the given join type, including all the
    # keys of row_a, the non-common keys of row_b for an :inner join, or all the
    # keys of row_b for other joins.  If any of the row_b keys are also row_a
    # keys, change the key name by appending a '_b' so the keys will not repeat.
    def build_out_row(row_a:, row_b:, common_heads: [], type: :inner)
      if type == :inner
        # Eliminate the keys that are common with row_a and were matched for
        # equality
        row_b = row_b.reject { |k, _| common_heads.include?(k) }
      end
      # Translate any remaining row_b heads to append '_b' if they have the
      # same name as a row_a key.
      a_heads = row_a.keys
      row_b = row_b.to_a.each.map { |k, v|
        [a_heads.include?(k) ? "#{k}_b".to_sym : k, v]
      }.to_h
      row_a.merge(row_b)
    end

    # Return a hash for the local variables of a join expression in which all
    # the keys in row_a have an '_a' appended and all the keys in row_b have a
    # '_b' appended.
    def build_locals_hash(row_a:, row_b:)
      row_a = row_a.to_a.each.map { |k, v| ["#{k}_a".to_sym, v] }.to_h
      row_b = row_b.to_a.each.map { |k, v| ["#{k}_b".to_sym, v] }.to_h
      row_a.merge(row_b)
    end

    # Return an array of two elements: (1) a ruby expression that expresses the
    # AND of all join conditions as described in the comment to the #join method
    # and (2) the heads from other table that (a) are known to be tested for
    # equality with a head in self table and (b) have the same name. Assume that
    # the expression will be evaluated in the context of a binding in which the
    # local variables are all the headers in the self table with '_a' appended
    # and all the headers in the other table with '_b' appended.
    def build_join_expression(exps, other, type)
      return ['true', []] if type == :cross
      a_heads = headers
      b_heads = other.headers
      common_heads = a_heads & b_heads
      b_common_heads = []
      if exps.empty?
        if common_heads.empty?
          raise ArgumentError,
                'A non-cross join with no common column names requires join expressions'
        else
          # A Natural join on all common heads
          common_heads.each do |h|
            ensure_common_types!(self_h: h, other_h: h, other: other)
          end
          nat_exp = common_heads.map { |h| "(#{h}_a == #{h}_b)" }.join(' && ')
          [nat_exp, common_heads]
        end
      else
        # We have expressions to evaluate
        and_conds = []
        partial_result = nil
        last_sym = nil
        exps.each do |exp|
          case exp
          when Symbol
            case exp.to_s.clean
            when /\A(.*)_a\z/
              a_head = $1.to_sym
              unless a_heads.include?(a_head)
                raise ArgumentError, "no column '#{a_head}' in table"
              end
              if partial_result
                # Second of a pair
                ensure_common_types!(self_h: a_head, other_h: last_sym, other: other)
                partial_result << "#{a_head}_a)"
                and_conds << partial_result
                partial_result = nil
              else
                # First of a pair of _a or _b
                partial_result = "(#{a_head}_a == "
              end
              last_sym = a_head
            when /\A(.*)_b\z/
              b_head = $1.to_sym
              unless b_heads.include?(b_head)
                raise ArgumentError, "no column '#{b_head}' in second table"
              end
              if partial_result
                # Second of a pair
                ensure_common_types!(self_h: last_sym, other_h: b_head, other: other)
                partial_result << "#{b_head}_b)"
                and_conds << partial_result
                partial_result = nil
              else
                # First of a pair of _a or _b
                partial_result = "(#{b_head}_b == "
              end
              b_common_heads << b_head
              last_sym = b_head
            else
              # No modifier, so must be one of the common columns
              unless partial_result.nil?
                # We were expecting the second of a modified pair, but got an
                # unmodified symbol instead.
                msg =
                  "must follow '#{last_sym}' by qualified exp from the other table"
                raise ArgumentError, msg
              end
              # We have an unqualified symbol that must appear in both tables
              unless common_heads.include?(exp)
                raise ArgumentError, "unqualified column '#{exp}' must occur in both tables"
              end
              ensure_common_types!(self_h: exp, other_h: exp, other: other)
              and_conds << "(#{exp}_a == #{exp}_b)"
              b_common_heads << exp
            end
          when String
            # We have a string expression in which all column references must be
            # qualified.
            and_conds << "(#{exp})"
          else
            raise ArgumentError, "invalid join expression '#{exp}' of class #{exp.class}"
          end
        end
        [and_conds.join(' && '), b_common_heads]
      end
    end

    # Raise an exception unless self_h in this table and other_h in other table
    # have the same types.
    def ensure_common_types!(self_h:, other_h:, other:)
      unless column(self_h).type == other.column(other_h).type
        raise ArgumentError,
              "type of column '#{self_h}' does not match type of column '#{other_h}"
      end
      self
    end

    ###################################################################################
    # Group By
    ###################################################################################

    public

    # Return a Table with a single row for each group of rows in the input table
    # where the value of all columns named as simple symbols are equal. All
    # other columns are set to the result of aggregating the values of that
    # column within the group according to a aggregate function (:count, :sum,
    # :min, :max, etc.), which defaults to the :first function, giving the value
    # of that column for the first row in the group.  You can specify a
    # different aggregate function for a column by adding a hash parameter with
    # the column as the key and a symbol for the aggregate function as the
    # value.  For example, consider the following call:
    #
    # tab.group_by(:date, :code, :price, shares: :sum, ).
    #
    # The first three parameters are simple symbols, so the table is divided
    # into groups of rows in which the value of :date, :code, and :price are
    # equal. The shares: hash parameter is set to the aggregate function :sum,
    # so it will appear in the result as the sum of all the :shares values in
    # each group. Any non-aggregate columns that have no aggregate function set
    # default to using the aggregate function :first. Because of the way Ruby
    # parses parameters to a method call, all the grouping symbols must appear
    # first in the parameter list before any hash parameters.
    def group_by(*group_cols, **agg_cols)
      default_agg_func = :first
      default_cols = headers - group_cols - agg_cols.keys
      default_cols.each do |h|
        agg_cols[h] = default_agg_func
      end

      sorted_tab = order_by(group_cols)
      groups = sorted_tab.rows.group_by do |r|
        group_cols.map { |k| r[k] }
      end
      result = Table.new
      groups.each_pair do |_vals, grp_rows|
        result << row_from_group(grp_rows, group_cols, agg_cols)
      end
      result.normalize_boundaries
      result
    end

    private

    def row_from_group(rows, grp_cols, agg_cols)
      new_row = {}
      grp_cols.each do |h|
        new_row[h] = rows.first[h]
      end
      agg_cols.each_pair do |h, agg_func|
        items = rows.map { |r| r[h] }
        new_h = "#{agg_func}_#{h}".as_sym
        new_row[new_h] = Column.new(header: h,
                                    items: items).send(agg_func)
      end
      new_row
    end

    ############################################################################
    # Table construction methods.
    ############################################################################

    public

    # Add a row represented by a Hash having the headers as keys. If mark is
    # true, mark this row as a boundary. All tables should be built ultimately
    # using this method as a primitive.
    def add_row(row, mark: false)
      row.each_pair do |k, v|
        key = k.as_sym
        columns << Column.new(header: k) unless column?(k)
        column(key) << v
      end
      @boundaries << (size - 1) if mark
      self
    end

    # Add a row without marking.
    def <<(row)
      add_row(row)
    end

    def add_column(col)
      raise "Table already has a column with header '#{col.header}'" if column?(col.header)
      columns << col
      self
    end
  end
end
