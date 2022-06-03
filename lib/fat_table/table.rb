# frozen_string_literal: true

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

    # Record boundaries set explicitly with mark_boundaries or from reading
    # hlines from input.  When we want to access boundaries, however, we want
    # to add an implict boundary at the last row of the table.  Since, as the
    # table grows, the implict boundary changes index, we synthesize the
    # boundaries by dynamically adding the final boundary with the #boundaries
    # method call.
    attr_accessor :explicit_boundaries

    # An Array of FatTable::Columns that should be tolerant.
    attr_reader :tolerant_columns

    ###########################################################################
    # Constructors
    ###########################################################################

    # :category: Constructors

    # Return an empty FatTable::Table object.  Specifying headers is optional.
    # Any headers ending with a ! are marked as tolerant, in that, if an
    # incompatible type is added to it, the column is re-typed as a String
    # column, and construction proceeds.  The ! is stripped from the header to
    # form the column key, though.  You can also provide the names of columns
    # that should be tolerant by using the +tolerant_columns key-word to
    # provide an array of headers that should be tolerant.  The special string
    # '*' or the symbol :* indicates that all columns should be created
    # tolerant.
    def initialize(*heads, tolerant_columns: [])
      @columns = []
      @explicit_boundaries = []
      @tolerant_columns =
        case tolerant_columns
        when Array
          tolerant_columns.map { |h| h.to_s.as_sym }
        when String
          if tolerant_columns.strip == '*'
            ['*'.to_sym]
          else
            [tolerant_columns.as_sym]
          end
        when Symbol
          if tolerant_columns.to_s.strip == '*'
            ['*'.to_sym]
          else
            [tolerant_columns.to_s.as_sym]
          end
        else
          raise ArgumentError, "set tolerant_columns to String, Symbol, or an Array of either"
        end
      unless heads.empty?
        heads.each do |h|
          if h.to_s.end_with?('!') || @tolerant_columns.include?(h)
            @columns << Column.new(header: h.to_s.sub(/!\s*\z/, ''), type: 'String')
          else
            @columns << Column.new(header: h)
          end
        end
      end
    end

    # :category: Constructors

    # Return an empty duplicate of self.  This allows the library to create an
    # empty table that preserves all the instance variables from self.  Even
    # though FatTable::Table objects have no instance variables, a class that
    # inherits from it might.
    def empty_dup
      dup.__empty!
    end

    def __empty!
      @columns = []
      @explicit_boundaries = []
      self
    end

    # :category: Constructors

    # Construct a Table from the contents of a CSV file named +fname+. Headers
    # will be taken from the first CSV row and converted to symbols.
    def self.from_csv_file(fname, tolerant_columns: [])
      File.open(fname, 'r') do |io|
        from_csv_io(io, tolerant_columns: tolerant_columns)
      end
    end

    # :category: Constructors

    # Construct a Table from a CSV string +str+, treated in the same manner as
    # the input from a CSV file in ::from_org_file.
    def self.from_csv_string(str, tolerant_columns: [])
      from_csv_io(StringIO.new(str), tolerant_columns: tolerant_columns)
    end

    # :category: Constructors

    # Construct a Table from the first table found in the given Emacs org-mode
    # file named +fname+. Headers are taken from the first row if the second row
    # is an hrule. Otherwise, synthetic headers of the form +:col_1+, +:col_2+,
    # etc. are created.
    def self.from_org_file(fname, tolerant_columns: [])
      File.open(fname, 'r') do |io|
        from_org_io(io, tolerant_columns: tolerant_columns)
      end
    end

    # :category: Constructors

    # Construct a Table from a string +str+, treated in the same manner as the
    # contents of an org-mode file in ::from_org_file.
    def self.from_org_string(str, tolerant_columns: [])
      from_org_io(StringIO.new(str), tolerant_columns: tolerant_columns)
    end

    # :category: Constructors

    # Construct a new table from an Array of Arrays +aoa+. By default, with
    # +hlines+ set to false, do not look for separators, i.e. +nils+, just
    # treat the first row as headers. With +hlines+ set true, expect +nil+
    # separators to mark the header row and any boundaries. If the second
    # element of the array is a +nil+, interpret the first element of the
    # array as a row of headers. Otherwise, synthesize headers of the form
    # +:col_1+, +:col_2+, ...  and so forth. The remaining elements are taken
    # as the body of the table, except that if an element of the outer array
    # is a +nil+, mark the preceding row as a group boundary. Note for Emacs
    # users: In org mode code blocks when an org-mode table is passed in as a
    # variable it is passed in as an Array of Arrays. By default (+ HEADER:
    # :hlines no +) org-mode strips all hrules from the table; otherwise (+
    # HEADER: :hlines yes +) they are indicated with nil elements in the outer
    # array.
    def self.from_aoa(aoa, hlines: false, tolerant_columns: [])
      from_array_of_arrays(aoa, hlines: hlines, tolerant_columns: tolerant_columns)
    end

    # :category: Constructors

    # Construct a Table from +aoh+, an Array of Hashes or an Array of any
    # objects that respond to the #to_h method. All hashes must have the same
    # keys, which, when converted to symbols will become the headers for the
    # Table. If hlines is set true, mark a group boundary whenever a nil, rather
    # than a hash appears in the outer array.
    def self.from_aoh(aoh, hlines: false, tolerant_columns: [])
      if aoh.first.respond_to?(:to_h)
        from_array_of_hashes(aoh, hlines: hlines, tolerant_columns: tolerant_columns)
      else
        raise UserError,
              "Cannot initialize Table with an array of #{input[0].class}"
      end
    end

    # :category: Constructors

    # Construct a new table from another FatTable::Table object +table+. Inherit
    # any group boundaries from the input table.
    def self.from_table(table)
      table.deep_dup
    end

    # :category: Constructors

    # Construct a Table by running a SQL +query+ against the database set up
    # with FatTable.connect, with the rows of the query result as rows.
    def self.from_sql(query, tolerant_columns: [])
      msg = 'FatTable.db must be set with FatTable.connect'
      raise UserError, msg if FatTable.db.nil?

      result = Table.new
      rows = FatTable.db[query]
      rows.each do |h|
        result << h
      end
      result
    end

    ############################################################################
    # Class-level constructor helpers
    ############################################################################

    class << self
      private

      # Construct table from an array of hashes or an array of any object that
      # can respond to #to_h. If an array element is a nil, mark it as a group
      # boundary in the Table.
      def from_array_of_hashes(hashes, hlines: false, tolerant_columns: [])
        result = new(tolerant_columns: tolerant_columns)
        hashes.each do |hsh|
          if hsh.nil?
            unless hlines
              msg = 'found an hline in input: try setting hlines true'
              raise UserError, msg
            end
            result.mark_boundary
            next
          end
          result << hsh.to_h
        end
        result.normalize_boundaries
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
      def from_array_of_arrays(rows, hlines: false, tolerant_columns: [])
        result = new(tolerant_columns: tolerant_columns)
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
              msg = 'found an hline in input: try setting hlines true'
              raise UserError, msg
            end
            result.mark_boundary
            next
          end
          row = row.map { |s| s.to_s.strip }
          hash_row = Hash[headers.zip(row)]
          result << hash_row
        end
        result.normalize_boundaries
        result
      end

      def from_csv_io(io, tolerant_columns: [])
        result = new(tolerant_columns: tolerant_columns)
        ::CSV.new(io, headers: true, header_converters: :symbol,
                  skip_blanks: true).each do |row|
          result << row.to_h
        end
        result.normalize_boundaries
        result
      end

      # Form rows of table by reading the first table found in the org file. The
      # header row must be marked with an hline (i.e, a row that looks like
      # '|---+--...--|') and groups of rows may be marked with hlines to
      # indicate group boundaries.
      def from_org_io(io, tolerant_columns: [])
        table_re = /\A\s*\|/
        hrule_re = /\A\s*\|[-+]+/
        rows = []
        table_found = false
        header_found = false
        io.each do |line|
          unless table_found
            # Skip through the file until a table is found
            next unless line.match?(table_re)

            unless line.match?(hrule_re)
              line = line.sub(/\A\s*\|/, '').sub(/\|\s*\z/, '')
              rows << line.split('|').map(&:clean)
            end
            table_found = true
            next
          end
          break unless line.match?(table_re)

          if !header_found && line =~ hrule_re
            rows << nil
            header_found = true
            next
          elsif header_found && line =~ hrule_re
            # Mark the boundary with a nil
            rows << nil
          elsif !line.match?(table_re)
            # Stop reading at the second hline
            break
          else
            line = line.sub(/\A\s*\|/, '').sub(/\|\s*\z/, '')
            rows << line.split('|').map(&:clean)
          end
        end
        from_array_of_arrays(rows, hlines: true, tolerant_columns: tolerant_columns)
      end
    end

    ###########################################################################
    # Attributes
    ###########################################################################

    # :category: Attributes

    # Return the table's Column with the given +key+ as its header.
    # @param key [Symbol] symbol for header of column to return
    # @return [FatTable::Column]
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

    # Set the column type for Column with the given +key+ as a String type,
    # but only if empty.  Otherwise, we would have to worry about converting
    # existing items in the column to String.  Perhaps that's a TODO.
    def force_string!(*keys)
      keys.each do |h|
        column(h).force_string!
      end
      self
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
        msg = "index '#{key}' out of range"
        raise UserError, msg unless (0..size - 1).cover?(key.abs)

        rows[key]
      when String
        msg = "header '#{key}' not in table"
        raise UserError, msg unless headers.include?(key)

        column(key).items
      when Symbol
        msg = "header ':#{key}' not in table"
        raise UserError, msg unless headers.include?(key)

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

    # Return whether the column with the given head should be made tolerant.
    def tolerant_col?(h)
      return true if tolerant_columns.include?(:'*')

      tolerant_columns.include?(h)
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

    ############################################################################
    # Enumerable
    ############################################################################

    public

    include Enumerable

    # :category: Attributes

    # Yield each row of the table as a Hash with the column symbols as keys.
    def each
      if block_given?
        rows.each do |row|
          yield row
        end
        self
      else
        to_enum(:each)
      end
    end

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
    # Boundaries can also be added manually with the +mark_boundary+ method.
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

    # Return the number of groups in the table.
    def number_of_groups
      empty? ? 0 : boundaries.size
    end

    # Return the range of row indexes for boundary number +k+
    def group_row_range(k)
      last_k = boundaries.size - 1
      if k < 0 || k > last_k
        raise ArgumentError, "boundary number '#{k}' out of range in boundary_row_range"
      end

      if boundaries.size == 1
        (0..boundaries.first)
      elsif k.zero?
        # Keep index at or above zero
        (0..boundaries[k])
      else
        ((boundaries[k - 1] + 1)..boundaries[k])
      end
    end

    # Return an Array of Column objects for header +col+ representing a
    # sub-column for each group in the table under that header.
    def group_cols(col)
      normalize_boundaries
      cols = []
      (0..boundaries.size - 1).each do |k|
        range = group_row_range(k)
        tab_col = column(col)
        gitems = tab_col.items[range]
        cols << Column.new(header: col, items: gitems,
                           type: tab_col.type, tolerant: tab_col.tolerant?)
      end
      cols
    end

    # :category: Operators

    # Return this table mutated with all groups removed. Useful after something
    # like #order_by, which adds groups as a side-effect, when you do not want
    # the groups displayed in the output. This modifies the input table, so is a
    # departure from the otherwise immutability of Tables.
    def degroup!
      self.explicit_boundaries = []
      self
    end

    # Mark a group boundary at row +row+, and if +row+ is +nil+, mark the last
    # row in the table as a group boundary.  An attempt to add a boundary to
    # an empty table has no effect.  We adopt the convention that the last row
    # of the table always marks an implicit boundary even if it is not in the
    # @explicit_boundaries array.  When we "mark" a boundary, we intend it to
    # be an explicit boundary, even if it marks the last row of the table.
    def mark_boundary(row_num = nil)
      return self if empty?

      if row_num
        unless row_num < size
          raise ArgumentError, "can't mark boundary at row #{row_num}, last row is #{size - 1}"
        end
        unless row_num >= 0
          raise ArgumentError, "can't mark boundary at non-positive row #{row_num}"
        end
        explicit_boundaries.push(row_num)
      elsif size > 0
        explicit_boundaries.push(size - 1)
      end
      normalize_boundaries
      self
    end

    # :stopdoc:

    # Make sure size - 1 is last boundary and that they are unique and sorted.
    def normalize_boundaries
      unless empty?
        self.explicit_boundaries = explicit_boundaries.uniq.sort
      end
      explicit_boundaries
    end

    # Return the explicit_boundaries, augmented by an implicit boundary for
    # the end of the table, unless it's already an implicit boundary.
    def boundaries
      return [] if empty?

      if explicit_boundaries.last == size - 1
        explicit_boundaries
      else
        explicit_boundaries + [size - 1]
      end
    end

    protected

    # Concatenate the array of argument bounds to this table's boundaries, but
    # increase each of the indexes in bounds by shift. This is used in the
    # #union_all method.
    def append_boundaries(bounds, shift: 0)
      @explicit_boundaries += bounds.map { |k| k + shift }
    end

    # Return the group number to which row ~row_num~ belongs. Groups, from the
    # user's point of view are indexed starting at 0.
    def row_index_to_group_index(row_num)
      boundaries.each_with_index do |b_last, g_num|
        return (g_num + 1) if row_num <= b_last
      end
      0
    end

    # Return the index of the first row in group number +grp_num+
    def first_row_num_in_group(grp_num)
      if grp_num >= boundaries.size || grp_num < 0
        raise ArgumentError, "group number #{grp_num} out of bounds"
      end

      grp_num.zero? ? 0 : boundaries[grp_num - 1] + 1
    end

    # Return the index of the last row in group number +grp_num+
    def last_row_num_in_group(grp_num)
      if grp_num > boundaries.size || grp_num < 0
        raise ArgumentError, "group number #{grp_num} out of bounds"
      else
        boundaries[grp_num]
      end
    end

    # Return the rows for group number +grp_num+.
    def group_rows(grp_num) # :nodoc:
      normalize_boundaries
      return [] unless grp_num < boundaries.size

      first = first_row_num_in_group(grp_num)
      last = last_row_num_in_group(grp_num)
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
      # Sort the rows in order and add to new_rows.
      key_hash = partition_sort_keys(sort_heads)
      new_rows = rows.sort do |r1, r2|
        # Set the sort keys based on direction
        key1 = []
        key2 = []
        key_hash.each_pair do |h, dir|
          if dir == :forward
            key1 << r1[h]
            key2 << r2[h]
          else
            key1 << r2[h]
            key2 << r1[h]
          end
        end
        # Make any booleans comparable with <=>
        key1 = key1.map_booleans
        key2 = key2.map_booleans

        # If there are any nils, <=> will return nil, and we have to use the
        # special comparison method, compare_with_nils, instead.
        result = (key1 <=> key2)
        result.nil? ? compare_with_nils(key1, key2) : result
      end

      # Add the new_rows to the table, but mark a group boundary at the points
      # where the sort key changes value.  NB: I use self.class.new here
      # rather than Table.new because if this class is inherited, I want the
      # new_tab to be an instance of the subclass.  With Table.new, this
      # method's result will be an instance of FatTable::Table rather than of
      # the subclass.
      new_tab = empty_dup
      last_key = nil
      new_rows.each_with_index do |nrow, k|
        new_tab << nrow
        key = nrow.fetch_values(*key_hash.keys)
        new_tab.mark_boundary(k - 1) if last_key && key != last_key
        last_key = key
      end
      new_tab.normalize_boundaries
      new_tab
    end

    # :category: Operators

    # Return a new Table sorting the rows of this Table on an any expression
    # +expr+ that is valid with the +select+ method, except that they
    # expression may end with an exclamation mark +!+ to indicate a reverse
    # sort.  The new table will have an additional column called +sort_key+
    # populated with the result of evaluating the given expression and will be
    # sorted (or reverse sorted) on that column.
    #
    #   tab.order_with('date.year') => table sorted by date's year
    #   tab.order_with('date.year!') => table reverse sorted by date's year
    #
    # After sorting, the output Table will have group boundaries added after
    # each row where the sort key changes.
    def order_with(expr)
      unless expr.is_a?(String)
        raise "must call FatTable::Table\#order_with with a single string expression"
      end
      rev = false
      if expr.match?(/\s*!\s*\z/)
        rev = true
        expr = expr.sub(/\s*!\s*\z/, '')
      end
      sort_sym = rev ? :sort_key! : :sort_key
      dup.select(*headers, sort_key: expr).order_by(sort_sym)
    end

    # :category: Operators
    #
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
    # 4. a hash in +new_cols+ with one of the special keys, +ivars: {literal
    #    hash}+, +before_hook: 'ruby-code'+, or +after_hook: 'ruby-code'+ for
    #    defining custom instance variables to be used during evaluation of
    #    parameters described in point 3 and hooks of ruby code snippets to be
    #    evaluated before and after processing each row.
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
    #
    # The instance variables and hooks mentioned in point 4 above allow you to
    # keep track of things that cross row boundaries, such as running sums or
    # the values of columns before or after construction of the new row. You can
    # define instance variables other than the default @row and @group variables
    # to be available when evaluating normal string expressions for constructing
    # a new row.
    #
    # You define custom instance variables by passing a Hash to the ivars
    # parameter. The names of the instance variables will be the keys and their
    # initial values will be the values. For example, you can keep track of a
    # running sum of the cost of shares and the number of shares in the prior
    # row by adding two custom instance variables and the appropriate hooks:
    #
    #   tab.select(:ref, :date, :shares, :price,
    #              cost: 'shares * price', cumulative_cost: '@total_cost'
    #              ivars: { total_cost: 0, prior_shares: 0},
    #              before_hook: '@total_cost += shares * price,
    #              after_hook: '@prior_shares = shares')
    #
    # Notice that in the +ivars:+ parameter, the '@' is not prefixed to the name
    # since it is a symbol, but must be prefixed when the instance variable is
    # referenced in an expression, otherwise it would be interpreted as a column
    # name.  You could include the '@' if you use a string as a key, e.g., +{
    # '@total_cost' => 0 }+  The ivars values are evaluated once, before the
    # first row is processed with the select statement.
    #
    # For each row, the +before_hook+ is evaluated, then the +new_cols+
    # expressions for setting the new value of columns, then the +after_hook+ is
    # evaluated.
    #
    # In the before_hook, the values of all columns are available as local
    # variables as they were before processing the row. The values of all
    # instance variables are available as well with the values they had after
    # processing the prior row of the table.
    #
    # In the string expressions for new columns, all the instance variables are
    # available with the values they have after the before_hook is evaluated.
    # You could also modify instance variables in the new_cols expression, but
    # remember, they are evaluated once for each new column expression. Also,
    # the new column is assigned the value of the entire expression, so you must
    # ensure that the last expression is the one you want assigned to the new
    # column. You might want to use a semicolon: +cost: '@total_cost += shares *
    # price; shares * price'
    #
    # In the after_hook, the new, updated values of all columns, old and new are
    # available as local variables, and the instance variables are available
    # with the values they had after executing the before_hook.
    def select(*cols, **new_cols)
      # Set up the Evaluator
      ivars = { row: 0, group: 0 }
      if new_cols.key?(:ivars)
        ivars = ivars.merge(new_cols[:ivars])
        new_cols.delete(:ivars)
      end
      if new_cols.key?(:before_hook)
        before_hook = new_cols[:before_hook].to_s
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
      result = empty_dup
      normalize_boundaries
      rows.each_with_index do |old_row, old_k|
        # Set the group number in the before hook and run the hook with the
        # local variables set to the row before the new row is evaluated.
        grp = row_index_to_group_index(old_k)
        ev.update_ivars(row: old_k + 1, group: grp)
        ev.eval_before_hook(locals: old_row)
        # Compute the new row.
        new_row = {}
        # Allow the :omni col to stand for all columns if it is alone and
        # first.
        cols_to_include =
          if cols.size == 1 && cols.first.as_sym == :omni
            headers
          else
            cols
          end
        cols_to_include.each do |k|
          h = k.as_sym
          msg = "Column '#{h}' in select does not exist"
          raise UserError, msg unless column?(h)

          new_row[h] = old_row[h]
        end
        new_cols.each_pair do |key, expr|
          key = key.as_sym
          vars = old_row.merge(new_row)
          case expr
          when Symbol
            msg = "Column '#{expr}' in select does not exist"
            raise UserError, msg unless vars.key?(expr)

            new_row[key] = vars[expr]
          when String
            begin
            new_row[key] = ev.evaluate(expr, locals: vars)
            rescue SyntaxError, NameError => ex
              # Treat uninitialized constant errors as literal strings.
              new_row[key] = expr # if ex.to_s.match?(/uninitialized constant/)
            end
          when Numeric, DateTime, Date, TrueClass, FalseClass
            new_row[key] = expr
          else
            msg = "Setting column at '#{key}' to '#{expr}' not allowed"
            raise UserError, msg
          end
        end
        # Set the group number and run the hook with the local variables set to
        # the row after the new row is evaluated.
        # vars = new_row.merge(__group: grp)
        ev.eval_after_hook(locals: new_row)
        result << new_row
      end
      result.explicit_boundaries = explicit_boundaries
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
      result = empty_dup
      headers.each do |h|
        col =
        if tolerant_col?(h)
          Column.new(header: h, tolerant: true)
        else
          Column.new(header: h)
        end
        result.add_column(col)
      end
      ev = Evaluator.new(ivars: { row: 0, group: 0 })
      rows.each_with_index do |row, k|
        grp = row_index_to_group_index(k)
        ev.update_ivars(row: k + 1, group: grp)
        ev.eval_before_hook(locals: row)
        result << row if ev.evaluate(expr, locals: row)
        ev.eval_after_hook(locals: row)
      end
      result.normalize_boundaries
      result
    end

    # :category: Operators

    # Return a new table with all duplicate rows eliminated. Resets groups. Same
    # as #uniq.
    def distinct
      result = empty_dup
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

    # An Array of symbols for the valid join types.
    JOIN_TYPES = %i[inner left right full cross].freeze

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
    # @param other [FatTable::Table] table to join with self
    # @param exps [Array<String>, Array<Symbol>] table to join with self
    # @param join_type [Array<String>, Array<Symbol>] type of join :inner, :left, :right, :full, :cross
    # @return [FatTable::Table] result of joining self to other
    #
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
      join_exp, other_common_heads =
        build_join_expression(exps, other, join_type)
      ev = Evaluator.new
      result = empty_dup
      other_rows = other.rows
      other_row_matches = Array.new(other_rows.size, false)
      rows.each do |self_row|
        self_row_matched = false
        other_rows.each_with_index do |other_row, k|
          # Same as other_row, but with keys that are common with self and equal
          # in value, removed, so the output table need not repeat them.
          locals = build_locals_hash(row_a: self_row, row_b: other_row)
          matches = ev.evaluate(join_exp, locals: locals)
          next unless matches

          self_row_matched = other_row_matches[k] = true
          out_row = build_out_row(row_a: self_row, row_b: other_row,
                                  common_heads: other_common_heads,
                                  type: join_type)
          result << out_row
        end
        next unless [:left, :full].include?(join_type)
        next if self_row_matched

        result << build_out_row(row_a: self_row,
                                row_b: other_row_nils,
                                type: join_type)
      end
      if [:right, :full].include?(join_type)
        other_rows.each_with_index do |other_row, k|
          next if other_row_matches[k]

          result << build_out_row(row_a: self_row_nils,
                                  row_b: other_row,
                                  type: join_type)
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
      row_b = row_b.to_a.each.map do |k, v|
        [a_heads.include?(k) ? "#{k}_b".to_sym : k, v]
      end
      row_a.merge(row_b.to_h)
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
          msg = "#{type}-join with no common column names needs join expression"
          raise UserError, msg
        else
          # A Natural join on all common heads
          common_heads.each do |h|
            ensure_common_types!(self_h: h, other_h: h, other: other)
          end
          nat_exp = common_heads.map { |h| "(#{h}_a == #{h}_b)" }.join(' && ')
          [nat_exp, common_heads]
        end
      else
        # We have join expressions to evaluate
        and_conds = []
        partial_result = nil
        last_sym = nil
        exps.each do |exp|
          case exp
          when Symbol
            case exp.to_s.clean
            when /\A(?<sy>.*)_a\z/
              a_head = Regexp.last_match[:sy].to_sym
              unless a_heads.include?(a_head)
                raise UserError, "no column '#{a_head}' in table"
              end

              if partial_result
                # Second of a pair
                ensure_common_types!(self_h: a_head,
                                     other_h: last_sym,
                                     other: other)
                partial_result << "#{a_head}_a)"
                and_conds << partial_result
                partial_result = nil
              else
                # First of a pair of _a or _b
                partial_result = +"(#{a_head}_a == "
              end
              last_sym = a_head
            when /\A(?<sy>.*)_b\z/
              b_head = Regexp.last_match[:sy].to_sym
              unless b_heads.include?(b_head)
                raise UserError, "no column '#{b_head}' in second table"
              end

              if partial_result
                # Second of a pair
                ensure_common_types!(self_h: last_sym,
                                     other_h: b_head,
                                     other: other)
                partial_result << "#{b_head}_b)"
                and_conds << partial_result
                partial_result = nil
              else
                # First of a pair of _a or _b
                partial_result = +"(#{b_head}_b == "
              end
              b_common_heads << b_head
              last_sym = b_head
            else
              # No modifier, so must be one of the common columns
              unless partial_result.nil?
                # We were expecting the second of a modified pair, but got an
                # unmodified symbol instead.
                msg =
                  "follow '#{last_sym}' by qualified exp from the other table"
                raise UserError, msg
              end
              # We have an unqualified symbol that must appear in both tables
              unless common_heads.include?(exp)
                msg = "unqualified column '#{exp}' must occur in both tables"
                raise UserError, msg
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
            msg = "invalid join expression '#{exp}' of class #{exp.class}"
            raise UserError, msg
          end
        end
        [and_conds.join(' && '), b_common_heads]
      end
    end

    # Raise an exception unless self_h in this table and other_h in other table
    # have the same types.
    def ensure_common_types!(self_h:, other_h:, other:)
      unless column(self_h).type == other.column(other_h).type
        msg = "column '#{self_h}' type does not match column '#{other_h}"
        raise UserError, msg
      end
      self
    end

    ############################################################################
    # Group By
    ############################################################################

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
      result = empty_dup
      groups.each_pair do |_vals, grp_rows|
        result << row_from_group(grp_rows, group_cols, agg_cols)
      end
      result.normalize_boundaries
      result
    end

    private

    # Collapse a group of rows to a single row by applying the aggregator from
    # the +agg_cols+ to the items in that column and the presumably identical
    # value in the +grp_cols to those columns.
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
      row.transform_keys!(&:as_sym)
      # Make sure there is a column for each known header and each new key
      # present in row.
      new_heads = row.keys - headers
      new_heads.each do |h|
        # This column is new, so it needs nil items for all prior rows lest
        # the value be added to a prior row.
        items = Array.new(size, nil)
        columns << Column.new(header: h, items: items, tolerant: tolerant_col?(h))
      end
      headers.each do |h|
        # NB: This adds a nil if h is not in row.
        column(h) << row[h]
      end
      self
    end

    # :category: Constructors

    # Add a +row+ to this Table without marking it as a group boundary.
    def <<(row)
      add_row(row)
    end

    # :category: Constructors

    # Add a FatTable::Column object +col+ to the table.
    def add_column(col)
      msg = "Table already has a column with header '#{col.header}'"
      raise msg if column?(col.header)

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
      msg = "unknown format '#{fmt}'"
      raise UserError, msg unless FatTable::FORMATS.include?(fmt)

      method = "to_#{fmt}"
      if block_given?
        send(method, options, &Proc.new)
      else
        send(method, options)
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
      fmt = Formatter.new(self, **options)
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
      fmt = FatTable::AoaFormatter.new(self, **options)
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
      fmt = AohFormatter.new(self, **options)
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
      fmt = LaTeXFormatter.new(self, **options)
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
      fmt = OrgFormatter.new(self, **options)
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
      fmt = TermFormatter.new(self, **options)
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
      fmt = TextFormatter.new(self, **options)
      yield fmt if block_given?
      fmt.output
    end

    private

    # Apply the set operation given by ~oper~ between this table and the other
    # table given in the first argument.  If distinct is true, eliminate
    # duplicates from the result.
    def set_operation(other, oper = :+, distinct: true, add_boundaries: true, inherit_boundaries: false)
      unless columns.size == other.columns.size
        msg = "can't apply set ops to tables with a different number of columns"
        raise UserError, msg
      end
      unless columns.map(&:type) == other.columns.map(&:type)
        msg = "can't apply a set ops to tables with different column types."
        raise UserError, msg
      end
      other_rows = other.rows.map { |r| r.replace_keys(headers) }
      result = empty_dup
      new_rows = rows.send(oper, other_rows)
      new_rows.each_with_index do |row, k|
        result << row
        result.mark_boundary if k == size - 1 && add_boundaries
      end
      if inherit_boundaries
        result.explicit_boundaries = boundaries
        result.append_boundaries(other.boundaries, shift: size)
      end
      result.normalize_boundaries
      distinct ? result.distinct : result
    end

    # Return a hash with the key being the header to sort on and the value
    # being either :forward or :reverse to indicate the sort order on that
    # key.
    def partition_sort_keys(keys)
      result = {}
      [keys].flatten.each do |h|
        if h.to_s.match?(/\s*!\s*\z/)
          result[h.to_s.sub(/\s*!\s*\z/, '').to_sym] = :reverse
        else
          result[h] = :forward
        end
      end
      result
    end

    # The <=> operator cannot handle nils without some help.  Treat a nil as
    # smaller than any other value, but equal to other nils.  The two keys are
    # assumed to be arrays of values to be compared with <=>.  Since
    # tolerant_columns permit strings to be mixed in with columns of type
    # Numeric, DateTime, and Boolean, treat strings mixed with another type
    # the same as nils.
    def compare_with_nils(key1, key2)
      result = nil
      key1.zip(key2) do |k1, k2|
        if k1.is_a?(String) && !k2.is_a?(String)
          k1 = nil
        elsif !k1.is_a?(String) && k2.is_a?(String)
          k2 = nil
        end
        if k1.nil? && k2.nil?
          result = 0
          next
        elsif k1.nil?
          result = -1
          break
        elsif k2.nil?
          result = 1
          break
        elsif (k1 <=> k2) == 0
          next
        else
          result = (k1 <=> k2)
          break
        end
      end
      result
    end
  end
end
