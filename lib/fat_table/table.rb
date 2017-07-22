module FatTable
  # A container for a two-dimensional table. All cells in the table must be a
  # String, a DateTime (or Date), a Numeric (Bignum, Integer, or BigDecimal), or
  # a Boolean (TrueClass or FalseClass). All columns must be of one of those
  # types or be a string convertible into one of them. It is considered an error
  # if a single column contains cells of different types. Any cell that cannot
  # be parsed as one of the Numeric, DateTime, or Boolean types will be treated
  # as a String and have #to_s applied. Until the column type is determined, it
  # will have the type NilClass.
  #
  # You can initialize a Table in several ways:
  #
  # 1. ::new, which will return an empty table to which rows or
  #    columns can be added later,
  #
  # 2. ::from_csv_file('table.csv'), where the argument is the
  #    name of a .csv file, in which case, the headers will be taken from the
  #    first row of the data.
  #
  # 3. ::from_org_file('table.org'), where the argument is the
  #    name of an .org file and the first Emacs org mode table found in the file
  #    will be read. The headers will be taken from the first row of the table
  #    if it is followed by an hrule, otherwise the headers will be synthesized
  #    as +:col_1+, +:col_2+, etc.
  #
  # 4. ::from_csv_string('csv_string'), where +csv_string+ is a
  #    string in the same form as a .csv file, and it will be parsed in the same
  #    way.
  #
  # 5. ::from_org_string('org_string'), where +org_string+ is a
  #    string in the same form as an Emacs org mode table, and it will be parsed
  #    in the same way.
  #
  # 6. ::from_aoa(+aoa+), where +aoa+ is an Array of elements that
  #    are either Arrays or nil. The headers will be taken from the first Array
  #    if it is followed by a nil, otherwise the headers will be synthesized as
  #    +:col_1+, +:col_2+, etc. Each inner Array will be read as a row of the
  #    table and each nil, after the first will be take as a group boundary.
  #
  # 7. ::from_aoh(+aoh+), where +aoh+ is an Array of elements each
  #    of which is either (1) a Hash (or any object that responds to #to_h) or
  #    (2) a nil. All Hashes must have the same keys, which become the headers
  #    for the table. Each nil will be taken as marking a group boundary.
  #
  # 9. ::from_table(+table+), where +table+ is another FatTable::Table
  #    object.
  #
  # In the resulting Table, the headers are converted into symbols, with all
  # spaces converted to underscore and everything down-cased. So, the heading,
  # 'Two Words' becomes the header +:two_words+.
  class Table

    # An Array of FatTable::Columns that constitute the table.
    attr_reader :columns

    ###########################################################################
    # Constructors
    ###########################################################################

    # :category: Constructors

    # Return an empty FatTable::Table object.
    def initialize
      @columns = []
      @boundaries = []
    end

    # :category: Constructors

    # Construct a Table from the contents of a CSV file named +fname+. Headers
    # will be taken from the first CSV row and converted to symbols.
    def self.from_csv_file(fname)
      File.open(fname, 'r') do |io|
        from_csv_io(io)
      end
    end

    # :category: Constructors

    # Construct a Table from a CSV string +str+, treated in the same manner as
    # the input from a CSV file in ::from_org_file.
    def self.from_csv_string(str)
      from_csv_io(StringIO.new(str))
    end

    # :category: Constructors

    # Construct a Table from the first table found in the given Emacs org-mode
    # file named +fname+. Headers are taken from the first row if the second row
    # is an hrule. Otherwise, synthetic headers of the form +:col_1+, +:col_2+,
    # etc. are created.
    def self.from_org_file(fname)
      File.open(fname, 'r') do |io|
        from_org_io(io)
      end
    end

    # :category: Constructors

    # Construct a Table from a string +str+, treated in the same manner as the
    # contents of an org-mode file in ::from_org_file.
    def self.from_org_string(str)
      from_org_io(StringIO.new(str))
    end

    # :category: Constructors

    # Construct a new table from an Array of Arrays +aoa+. By default, with
    # +hlines+ set to false, do not look for separators, i.e. +nils+, just treat
    # the first row as headers. With +hlines+ set true, expect +nil+ separators
    # to mark the header row and any boundaries. If the second element of the
    # array is a +nil+, interpret the first element of the array as a row of
    # headers. Otherwise, synthesize headers of the form +:col_1+, +:col_2+, ...
    # and so forth. The remaining elements are taken as the body of the table,
    # except that if an element of the outer array is a +nil+, mark the
    # preceding row as a group boundary. Note for Emacs users: In org mode code
    # blocks when an org-mode table is passed in as a variable it is passed in
    # as an Array of Arrays. By default (+ HEADER: :hlines no +) org-mode strips
    # all from the table; otherwise (+ HEADER: :hlines yes +) they are indicated
    # with nil elements in the outer array.
    def self.from_aoa(aoa, hlines: false)
      from_array_of_arrays(aoa, hlines: hlines)
    end

    # :category: Constructors

    # Construct a Table from +aoh+, an Array of Hashes or an Array of any
    # objects that respond to the #to_h method. All hashes must have the same
    # keys, which, when converted to symbols will become the headers for the
    # Table. If hlines is set true, mark a group boundary whenever a nil, rather
    # than a hash appears in the outer array.
    def self.from_aoh(aoh, hlines: false)
      if aoh.first.respond_to?(:to_h)
        from_array_of_hashes(aoh, hlines: hlines)
      else
        raise UserError,
              "Cannot initialize Table with an array of #{input[0].class}"
      end
    end

    # :category: Constructors

    # Construct a new table from another FatTable::Table object +table+. Inherit any
    # group boundaries from the input table.
    def self.from_table(table)
      table.deep_dup
    end

    # :category: Constructors

    # Construct a Table by running a SQL +query+ against the database set up
    # with FatTable.set_db, with the rows of the query result as rows.
    def self.from_sql(query)
      raise UserError, 'FatTable.db must be set with FatTable.set_db' if FatTable.db.nil?
      result = Table.new
      sth = FatTable.db.prepare(query)
      sth.execute
      sth.fetch_hash do |h|
        result << h
      end
      result
    end

    ############################################################################
    # Class-level constructor helpers
    ############################################################################

    class << self
      private

      # Construct table from an array of hashes or an array of any object that can
      # respond to #to_h.  If an array element is a nil, mark it as a group
      # boundary in the Table.
      def from_array_of_hashes(hashes, hlines: false)
        result = new
        hashes.each do |hsh|
          if hsh.nil?
            unless hlines
              raise UserError, 'found an hline in input with hlines false; try setting hlines true'
            end
            result.mark_boundary
            next
          end
          result << hsh.to_h
        end
        result
      end

      # Construct a new table from an array of arrays. By default, with hlines
      # false, do not look for separators, i.e. nils, just treat the first row
      # as headers. With hlines true, expect nil separators to mark the header
      # row and any boundaries. If the second element of the array is a nil,
      # interpret the first element of the array as a row of headers. Otherwise,
      # synthesize headers of the form :col_1, :col_2, ... and so forth. The
      # remaining elements are taken as the body of the table, except that if an
      # element of the outer array is a nil, mark the preceding row as a group
      # boundary. Note: In org mode code blocks, by default (:hlines no) all
      # hlines are stripped from the table, otherwise (:hlines yes) they are
      # indicated with nil elements in the outer array as expected by this
      # method when hlines is set true.
      def from_array_of_arrays(rows, hlines: false)
        result = new
        headers = []
        if !hlines
          # Take the first row as headers
          # Second row et seq as data
          headers = rows[0].map(&:to_s).map(&:as_sym)
          first_data_row = 1
        elsif rows[1].nil?
          # Use first row 0 as headers
          # Row 1 is an hline
          # Row 2 et seq are data
          headers = rows[0].map(&:to_s).map(&:as_sym)
          first_data_row = 2
        else
          # Synthesize headers
          # Row 0 et seq are data
          headers = (1..rows[0].size).to_a.map { |k| "col_#{k}".as_sym }
          first_data_row = 0
        end
        rows[first_data_row..-1].each do |row|
          if row.nil?
            unless hlines
              raise UserError, 'found an hline in input with hlines false; try setting hlines true'
            end
            result.mark_boundary
            next
          end
          row = row.map { |s| s.to_s.strip }
          hash_row = Hash[headers.zip(row)]
          result << hash_row
        end
        result
      end

      def from_csv_io(io)
        result = new
        ::CSV.new(io, headers: true, header_converters: :symbol,
                  skip_blanks: true).each do |row|
          result << row.to_h
        end
        result
      end

      # Form rows of table by reading the first table found in the org file. The
      # header row must be marked with an hline (i.e, a row that looks like
      # '|---+--...--|') and groups of rows may be marked with hlines to
      # indicate group boundaries.
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
        from_array_of_arrays(rows, hlines: true)
      end
    end

    ###########################################################################
    # Attributes
    ###########################################################################

    # :category: Attributes

    # Return the table's Column with the given +key+ as its header.
    def column(key)
      columns.detect { |c| c.header == key.as_sym }
    end

    # :category: Attributes

    # Return the type of the Column with the given +key+ as its
    # header as a String.
    def type(key)
      column(key).type
    end

    # :category: Attributes

    # Return the array of items of the column with the given header symbol
    # +key+, or if +key+ is an Integer, return that row at that index. So a
    # table's rows can be accessed by number, and its columns can be accessed by
    # column header. Also, double indexing works in either row-major or
    # column-major order: \tab\[:id\]\[8\] returns the 9th item in the column
    # headed :id and so does \tab\[8\]\[:id\].
    def [](key)
      case key
      when Integer
        raise UserError, "index '#{key}' out of range" unless (0..size-1).cover?(key.abs)
        rows[key]
      when String
        raise UserError, "header '#{key}' not in table" unless headers.include?(key)
        column(key).items
      when Symbol
        raise UserError, "header ':#{key}' not in table" unless headers.include?(key)
        column(key).items
      else
        raise UserError, "cannot index table with a #{key.class}"
      end
    end

    # :category: Attributes

    # Return true if the table has a Column with the given +key+ as a header.
    def column?(key)
      headers.include?(key.as_sym)
    end

    # :category: Attributes

    # Return a Hash of the Table's Column header symbols to type strings.
    def types
      result = {}
      columns.each do |c|
        result[c.header] = c.type
      end
      result
    end

    # :category: Attributes

    # Return the headers for the Table as an Array of Symbols.
    def headers
      columns.map(&:header)
    end

    # :category: Attributes

    # Return the number of rows in the Table.
    def size
      return 0 if columns.empty?
      columns.first.size
    end

    # :category: Attributes

    # Return the number of Columns in the Table.
    def width
      return 0 if columns.empty?
      columns.size
    end

    # :category: Attributes

    # Return whether this Table is empty.
    def empty?
      size.zero?
    end

    # :category: Attributes

    # Return the rows of the Table as an Array of Hashes, keyed by the headers.
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

    # :category: Attributes

    # Return the rows from first to last. We could just index #rows, but in a
    # large table, that would require that we construct all the rows for a range
    # of any size.
    def rows_range(first = 0, last = nil) # :nodoc:
      last ||= size - 1
      last = [last, 0].max
      raise UserError, 'first must be <= last' unless first <= last
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

    #############################################################################
    # Enumerable
    #############################################################################

    public

    include Enumerable

    # :category: Attributes

    # Yield each row of the table as a Hash with the column symbols as keys.
    def each
      rows.each do |row|
        yield row
      end
    end


    public

    # :category: Attributes

    # Boundaries mark the last row in each "group" within the table. The last
    # row of the table is always an implicit boundary, and having the last row
    # as the sole boundary is the default for new tables unless mentioned
    # otherwise. Resetting the boundaries means to put it back in that default
    # state.
    #
    # Boundaries can be added when a table is read in, for example, from the
    # text of an org table in which each hline (other than the one separating
    # the headers from the body) marks a boundary for the row immediately
    # preceding the hline.
    #
    # The #order_by method resets the boundaries then adds boundaries at the
    # last row of each group of rows on which the sort keys were equal as a
    # boundary.
    #
    # The #union_all (but not #union since it deletes duplicates) method adds a
    # boundary between the constituent tables. #union_all also preserves any
    # boundary markers within the constituent tables. In doing so, the
    # boundaries of the second table in the #union_all are increased by the size
    # of the first table so that they refer to rows in the new table.
    #
    # The #select method preserves any boundaries from the input table without
    # change, since it only selects columns for the output and deletes no rows.
    #
    # Perhaps surprisingly, the #group_by method does /not/ result in any groups
    # in the output table since the result of #group_by is to reduce all groups
    # it finds into a single row, and having a group for each row of the output
    # table would have no use.
    #
    # All the other table-transforming methods reset the boundaries in the new
    # table. For example, #where re-arranges and deletes rows, so the old
    # boundaries would make no sense anyway. Likewise, #union, #intersection,
    # #except, and #join reset the boundaries to their default.
    #
    # Return an array of an Array of row Hashes for the groups in this Table.
    def groups
      normalize_boundaries
      groups = []
      (0..boundaries.size - 1).each do |k|
        groups << group_rows(k)
      end
      groups
    end

    # :category: Operators

    # Return this table mutated with all groups removed. Useful after something
    # like #order_by, which adds groups as a side-effect, when you do not want
    # the groups displayed in the output. This modifies the input table, so is a
    # departure from the otherwise immutability of Tables.
    def degroup!
      @boundaries = []
      self
    end

    # Mark a group boundary at row +k+, and if +k+ is +nil+, mark the last row
    # in the table as a group boundary. This is mainly used for internal
    # purposes.
    def mark_boundary(k = nil) # :nodoc:
      if k
        boundaries.push(k)
      else
        boundaries.push(size - 1)
      end
    end

    protected

    # :stopdoc:

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

    def group_rows(k) # :nodoc:
      normalize_boundaries
      return [] unless k < boundaries.size
      first = k.zero? ? 0 : boundaries[k - 1] + 1
      last = boundaries[k]
      rows_range(first, last)
    end

    # :startdoc:

    ############################################################################
    # SQL look-alikes. The following methods are based on SQL equivalents and
    # all return a new Table object rather than modifying the table in place.
    ############################################################################

    public

    # :category: Operators

    # Return a new Table sorting the rows of this Table on the possibly multiple
    # keys given in +sort_heads+ as an Array of Symbols. Append a ! to the
    # symbol name to indicate reverse sorting on that column.
    #
    #   tab.order_by(:ref, :date) => sorted table
    #   tab.order_by(:date!) => reverse sort on :date
    #
    # After sorting, the output Table will have group boundaries added after
    # each row where the sort key changes.
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

    # :category: Operators

    # Return a Table having the selected column expressions. Each expression can
    # be either a
    #
    # 1. in +cols+, a symbol, +:old_col+, representing a column in the current
    #    table,
    #
    # 2. a hash in +new_cols+ of the form +new_col: :old_col+ to rename an
    #    existing +:old_col+ column as +:new_col+, or
    #
    # 3. a hash in +new_cols+ of the form +new_col: 'expression'+, to add a new
    #    column +new_col+ that is computed as an arbitrary ruby expression in
    #    which there are local variables bound to the names of existing columns
    #    (whether selected for the output table or not) as well as any +new_col+
    #    defined earlier in the argument list. The expression string can also
    #    access the instance variable @row, as the row number of the row being
    #    evaluated, and @group, as the group number of the row being evaluated.
    #
    # The bare symbol arguments +cols+ (1) must precede any hash arguments
    # +new_cols+ (2 or 3). Each expression results in a column in the resulting
    # Table in the order given in the argument list. The expressions are
    # evaluated in left-to-right order as well. The output table preserves any
    # groups present in the input table.
    #
    #   tab.select(:ref, :date, :shares) => table with only 3 columns selected
    #   tab.select(:ref, :date, shares: :quantity) => rename :shares->:quantity
    #   tab.select(:ref, :date, :shares, cost: 'price * shares') => new column
    #   tab.select(:ref, :date, :shares, seq: '@row') => add sequential nums
    def select(*cols, **new_cols)
      # Set up the Evaluator
      ivars = { row: 0, group: 0 }
      if new_cols.key?(:ivars)
        ivars = ivars.merge(new_cols[:ivars])
        new_cols.delete(:ivars)
      end
      before_hook = '@row += 1'
      if new_cols.key?(:before_hook)
        before_hook += "; #{new_cols[:before_hook]}"
        new_cols.delete(:before_hook)
      end
      after_hook = nil
      if new_cols.key?(:after_hook)
        after_hook = new_cols[:after_hook].to_s
        new_cols.delete(:after_hook)
      end
      ev = Evaluator.new(ivars: ivars,
                         before: before_hook,
                         after: after_hook)
      # Compute the new Table from this Table
      result = Table.new
      normalize_boundaries
      rows.each_with_index do |old_row, old_k|
        # Set the group number in the before hook and run the hook with the
        # local variables set to the row before the new row is evaluated.
        grp = row_index_to_group_index(old_k)
        vars = old_row.merge(__group: grp)
        ev.eval_before_hook(vars)
        # Compute the new row.
        new_row = {}
        cols.each do |k|
          h = k.as_sym
          raise UserError, "Column '#{h}' in select does not exist" unless column?(h)
          new_row[h] = old_row[h]
        end
        new_cols.each_pair do |key, val|
          key = key.as_sym
          vars = old_row.merge(new_row)
          case val
          when Symbol
            raise UserError, "Column '#{val}' in select does not exist" unless vars.keys.include?(val)
            new_row[key] = vars[val]
          when String
            new_row[key] = ev.evaluate(val, vars: vars)
          else
            raise UserError, "Hash parameter '#{key}' to select must be a symbol or string"
          end
        end
        # Set the group number and run the hook with the local variables set to
        # the row after the new row is evaluated.
        vars = new_row.merge(__group: grp)
        ev.eval_after_hook(vars)
        result << new_row
      end
      result.boundaries = boundaries
      result.normalize_boundaries
      result
    end

    # :category: Operators

    # Return a Table containing only rows for which the Ruby where expression,
    # +exp+, evaluates to a truthy value. Within the string expression +exp+,
    # each header is a local variable bound to the value of the current row in
    # that column, and the instance variables @row and @group are available as
    # the row and group number of the row being evaluated. Any groups present in
    # the input Table are eliminated in the output Table.
    #
    #   tab.where('date > Date.today - 30') => rows with recent dates
    #   tab.where('@row.even? && shares > 500') => even rows with lots of shares
    def where(expr)
      expr = expr.to_s
      result = Table.new
      headers.each do |h|
        col = Column.new(header: h)
        result.add_column(col)
      end
      ev = Evaluator.new(ivars: { row: 0, group: 0 },
                         before: '@row += 1')
      rows.each_with_index do |row, k|
        grp = row_index_to_group_index(k)
        vars = row.merge(__group: grp)
        ev.eval_before_hook(vars)
        result << row if ev.evaluate(expr, vars: vars)
        ev.eval_after_hook(vars)
      end
      result.normalize_boundaries
      result
    end

    # :category: Operators

    # Return a new table with all duplicate rows eliminated. Resets groups. Same
    # as #uniq.
    def distinct
      result = Table.new
      uniq_rows = rows.uniq
      uniq_rows.each do |row|
        result << row
      end
      result
    end

    # :category: Operators

    # Return this table with all duplicate rows eliminated. Resets groups. Same
    # as #distinct.
    def uniq
      distinct
    end

    # :category: Operators

    # Return a Table that combines this table with +other+ table, i.e., return
    # the union of this table with the other. The headers of this table are used
    # in the result. There must be the same number of columns of the same type
    # in the two tables, otherwise an exception will be raised. Duplicates are
    # eliminated from the result. Any groups present in either Table are
    # eliminated in the output Table.
    def union(other)
      set_operation(other, :+,
                    distinct: true,
                    add_boundaries: true)
    end

    # :category: Operators

    # Return a Table that combines this table with +other+ table. In other
    # words, return the union of this table with the other. The headers of this
    # table are used in the result. There must be the same number of columns of
    # the same type in the two tables, or an exception will be thrown.
    # Duplicates are not eliminated from the result. Adds group boundaries at
    # boundaries of the constituent tables. Preserves and adjusts the group
    # boundaries of the constituent table.
    def union_all(other)
      set_operation(other, :+,
                    distinct: false,
                    add_boundaries: true,
                    inherit_boundaries: true)
    end

    # :category: Operators

    # Return a Table that includes the rows that appear in this table and in
    # +other+ table. In other words, return the intersection of this table with
    # the other. The headers of this table are used in the result. There must be
    # the same number of columns of the same type in the two tables, or an
    # exception will be thrown. Duplicates are eliminated from the result. Any
    # groups present in either Table are eliminated in the output Table.
    def intersect(other)
      set_operation(other, :intersect, distinct: true)
    end

    # :category: Operators

    # Return a Table that includes all the rows in this table that also occur in
    # +other+ table. Note that the order of the operands matters. Duplicates in
    # this table will be included in the output, but duplicates in other will
    # not. The headers of this table are used in the result. There must be the
    # same number of columns of the same type in the two tables, or an exception
    # will be thrown. Duplicates are not eliminated from the result. Resets
    # groups.
    def intersect_all(other)
      set_operation(other, :intersect, distinct: false)
    end

    # :category: Operators

    # Return a Table that includes the rows of this table except for any rows
    # that are the same as those in Table +other+. In other words, return the
    # set difference between this table and +other+. The headers of this table
    # are used in the result. There must be the same number of columns of the
    # same type in the two tables, or an exception will be raised. Duplicates
    # are eliminated from the result. Any groups present in either Table are
    # eliminated in the output Table.
    def except(other)
      set_operation(other, :difference, distinct: true)
    end

    # :category: Operators

    # Return a Table that includes the rows of this table except for any rows
    # that are the same as those in Table +other+. In other words, return the
    # set difference between this table an the other. The headers of this table
    # are used in the result. There must be the same number of columns of the
    # same type in the two tables, or an exception will be thrown. Duplicates
    # are /not/ eliminated from the result. Any groups present in either Table
    # are eliminated in the output Table.
    def except_all(other)
      set_operation(other, :difference, distinct: false)
    end

    private

    # Apply the set operation given by op between this table and the other table
    # given in the first argument.  If distinct is true, eliminate duplicates
    # from the result.
    def set_operation(other, op = :+,
                      distinct: true,
                      add_boundaries: true,
                      inherit_boundaries: false)
      unless columns.size == other.columns.size
        raise UserError, 'Cannot apply a set operation to tables with a different number of columns.'
      end
      unless columns.map(&:type) == other.columns.map(&:type)
        raise UserError, 'Cannot apply a set operation to tables with different column types.'
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

    # An Array of symbols for the valid join types.
    JOIN_TYPES = [:inner, :left, :right, :full, :cross].freeze

    # :category: Operators
    #
    # Return a table that joins this Table to +other+ based on one or more join
    # expressions +exps+ using the +join_type+ in determining the rows of the
    # result table. There are several possible forms for the join expressions
    # +exps+:
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
    #    modifiers whether they are common to both tables or not. The names of
    #    the columns in both tables (without the leading ':' for symbols) are
    #    available as variables within the expression.
    #
    # The join_type parameter specifies what sort of join is performed, :inner,
    # :left, :right, :full, or :cross. The default is an :inner join. The types
    # of joins are defined as follows where T1 means this table, the receiver,
    # and T2 means other. These descriptions are taken from the Postgresql
    # documentation.
    #
    # :inner:: For each row R1 of T1, the joined table has a row for each row in
    #          T2 that satisfies the join condition with R1.
    #
    # :left:: First, an inner join is performed. Then, for each row in T1 that
    #         does not satisfy the join condition with any row in T2, a joined
    #         row is added with null values in columns of T2. Thus, the joined
    #         table always has at least one row for each row in T1.
    #
    # :right:: First, an inner join is performed. Then, for each row in T2 that
    #          does not satisfy the join condition with any row in T1, a joined
    #          row is added with null values in columns of T1. This is the
    #          converse of a left join: the result table will always have a row
    #          for each row in T2.
    #
    # :full:: First, an inner join is performed. Then, for each row in T1 that
    #         does not satisfy the join condition with any row in T2, a joined
    #         row is added with null values in columns of T2. Also, for each row
    #         of T2 that does not satisfy the join condition with any row in T1,
    #         a joined row with null values in the columns of T1 is added.
    #
    # :cross:: For every possible combination of rows from T1 and T2 (i.e., a
    #          Cartesian product), the joined table will contain a row
    #          consisting of all columns in T1 followed by all columns in T2. If
    #          the tables have N and M rows respectively, the joined table will
    #          have N * M rows.
    #
    # Any groups present in either Table are eliminated in the output Table. See
    # the README for examples.
    def join(other, *exps, join_type: :inner)
      unless other.is_a?(Table)
        raise UserError, 'need other table as first argument to join'
      end
      unless JOIN_TYPES.include?(join_type)
        raise UserError, "join_type may only be: #{JOIN_TYPES.join(', ')}"
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

    # :category: Operators

    # Perform an inner join as described in FatTable::Table#join.
    def inner_join(other, *exps)
      join(other, *exps)
    end

    # :category: Operators

    # Perform a left join as described in FatTable::Table#join.
    def left_join(other, *exps)
      join(other, *exps, join_type: :left)
    end

    # :category: Operators

    # Perform a right join as described in FatTable::Table#join.
    def right_join(other, *exps)
      join(other, *exps, join_type: :right)
    end

    # :category: Operators

    # Perform a full join as described in FatTable::Table#join.
    def full_join(other, *exps)
      join(other, *exps, join_type: :full)
    end

    # :category: Operators

    # Perform a cross join as described in FatTable::Table#join.
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
          raise UserError,
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
                raise UserError, "no column '#{a_head}' in table"
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
                raise UserError, "no column '#{b_head}' in second table"
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
                raise UserError, msg
              end
              # We have an unqualified symbol that must appear in both tables
              unless common_heads.include?(exp)
                raise UserError, "unqualified column '#{exp}' must occur in both tables"
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
            raise UserError, "invalid join expression '#{exp}' of class #{exp.class}"
          end
        end
        [and_conds.join(' && '), b_common_heads]
      end
    end

    # Raise an exception unless self_h in this table and other_h in other table
    # have the same types.
    def ensure_common_types!(self_h:, other_h:, other:)
      unless column(self_h).type == other.column(other_h).type
        raise UserError,
              "type of column '#{self_h}' does not match type of column '#{other_h}"
      end
      self
    end

    ###################################################################################
    # Group By
    ###################################################################################

    public

    # :category: Operators

    # Return a Table with a single row for each group of rows in the input table
    # where the value of all columns +group_cols+ named as simple symbols are
    # equal. All other columns, +agg_cols+, are set to the result of aggregating
    # the values of that column within the group according to a aggregate
    # function (:count, :sum, :min, :max, etc.) that you can specify by adding a
    # hash parameter with the column as the key and a symbol for the aggregate
    # function as the value. For example, consider the following call:
    #
    # tab.group_by(:date, :code, :price, shares: :sum).
    #
    # The first three parameters are simple symbols and count as +group_cols+,
    # so the table is divided into groups of rows in which the value of :date,
    # :code, and :price are equal. The shares: hash parameter is an +agg_col+
    # parameter set to the aggregate function :sum, so it will appear in the
    # result as the sum of all the :shares values in each group. Because of the
    # way Ruby parses parameters to a method call, all the grouping symbols must
    # appear first in the parameter list before any hash parameters.
    def group_by(*group_cols, **agg_cols)
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

    # :category: Constructors

    # Add a +row+ represented by a Hash having the headers as keys. If +mark:+
    # is set true, mark this row as a boundary. All tables should be built
    # ultimately using this method as a primitive.
    def add_row(row, mark: false)
      row.each_pair do |k, v|
        key = k.as_sym
        columns << Column.new(header: k) unless column?(k)
        column(key) << v
      end
      @boundaries << (size - 1) if mark
      self
    end

    # :category: Constructors

    # Add a +row+ without marking it as a group boundary.
    def <<(row)
      add_row(row)
    end

    # :category: Constructors

    # Add a FatTable::Column object +col+ to the table.
    def add_column(col)
      raise "Table already has a column with header '#{col.header}'" if column?(col.header)
      columns << col
      self
    end

    ############################################################################
    # Convenience output methods
    ############################################################################

    # :category: Output

    # In the same spirit as the FatTable module-level functions, the following
    # simply tee-up a Formatter for self so that the user need not instantiate
    # actual Formatter objects. Thus, one of these methods can be invoked as the
    # last method in a chain of Table operations.

    # :category: Output

    # Return a string or ruby object according to the format specified in
    # FatTable.format, passing the +options+ on to the Formatter. If a block is
    # given, it will yield a Formatter of the appropriate type to which format
    # and footers can be applied. Otherwise, the default format for the type
    # will be used.
    #
    # :call-seq: to_format(options = {}) { |fmt| ... }
    #
    def to_format(options = {})
      if block_given?
        to_any(FatTable.format, self, options, &Proc.new)
      else
        to_any(FatTable.format, self, options)
      end
    end

    # :category: Output

    # Return a string or ruby object according to the format type +fmt_type+
    # given in the first argument, passing the +options+ on to the Formatter.
    # Valid format types are :psv, :aoa, :aoh, :latex, :org, :term, :text, or
    # their string equivalents. If a block is given, it will yield a Formatter
    # of the appropriate type to which format and footers can be applied.
    # Otherwise, the default format for the type will be used.
    #
    # :call-seq: to_any(fmt_type, options = {}) { |fmt| ... }
    #
    def to_any(fmt_type, options = {})
      fmt = fmt_type.as_sym
      raise UserError, "unknown format '#{fmt}'" unless FatTable::FORMATS.include?(fmt)
      method = "to_#{fmt}"
      if block_given?
        send method, options, &Proc.new
      else
        send method, options
      end
    end

    # :category: Output

    # Return the table as a string formatted as a pipe-separated values, passing
    # the +options+ on to the Formatter. If no block is given, default
    # formatting is applies to the table's cells. If a block is given, it yields
    # a Formatter to the block to which formatting instructions and footers can
    # be added by calling methods on it. Since the pipe-separated format is the
    # default format for Formatter, there is no class PsvFormatter as you might
    # expect.
    def to_psv(options = {})
      fmt = Formatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as an Array of Array of Strings, passing the +options+ on
    # to the AoaFormatter. If no block is given, default formatting is applies
    # to the table's cells. If a block is given, it yields an AoaFormatter to
    # the block to which formatting instructions and footers can be added by
    # calling methods on it.
    def to_aoa(options = {})
      fmt = FatTable::AoaFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as an Array of Hashes, passing the +options+ on to the
    # AohFormatter. Each inner hash uses the Table's columns as keys and it
    # values are strings representing the cells of the table. If no block is
    # given, default formatting is applies to the table's cells. If a block is
    # given, it yields an AohFormatter to the block to which formatting
    # instructions and footers can be added by calling methods on it.
    def to_aoh(options = {})
      fmt = AohFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as a string containing a LaTeX table, passing the
    # +options+ on to the LaTeXFormatter. If no block is given, default
    # formatting applies to the table's cells. If a block is given, it yields a
    # LaTeXFormatter to the block to which formatting instructions and footers
    # can be added by calling methods on it.
    def to_latex(options = {})
      fmt = LaTeXFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as a string containing an Emacs org-mode table, passing
    # the +options+ on to the OrgFormatter. If no block is given, default
    # formatting applies to the table's cells. If a block is given, it yields a
    # OrgFormatter to the block to which formatting instructions and footers can
    # be added by calling methods on it.
    def to_org(options = {})
      fmt = OrgFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as a string containing ANSI terminal text representing
    # table, passing the +options+ on to the TermFormatter. If no block is
    # given, default formatting applies to the table's cells. If a block is
    # given, it yields a TermFormatter to the block to which formatting
    # instructions and footers can be added by calling methods on it.
    def to_term(options = {})
      fmt = TermFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end

    # :category: Output

    # Return the table as a string containing ordinary text representing table,
    # passing the +options+ on to the TextFormatter. If no block is given,
    # default formatting applies to the table's cells. If a block is given, it
    # yields a TextFormatter to the block to which formatting instructions and
    # footers can be added by calling methods on it.
    # @return [String]
    def to_text(options = {})
      fmt = TextFormatter.new(self, options)
      yield fmt if block_given?
      fmt.output
    end
  end
end
