# frozen_string_literal: true

# Gem Overview (extracted from README.org by gem_docs)
#
# * Introduction
# ~FatTable~ is a gem that treats tables as a data type. It provides methods for
# constructing tables from a variety of sources, building them row-by-row,
# extracting rows, columns, and cells, and performing aggregate operations on
# columns. It also provides a set of SQL-esque methods for manipulating table
# objects: ~select~ for filtering by columns or for creating new columns, ~where~
# for filtering by rows, ~order_by~ for sorting rows, ~distinct~ for eliminating
# duplicate rows, ~group_by~ for aggregating multiple rows into single rows and
# applying column aggregate methods to ungrouped columns, a collection of ~join~
# methods for combining tables, and more.
#
# Furthermore, ~FatTable~ provides methods for formatting tables and producing
# output that targets various output media: text, ANSI terminals, ruby data
# structures, LaTeX tables, Emacs org-mode tables, and more. The formatting
# methods can specify cell formatting in a way that is uniform across all the
# output methods and can also decorate the output with any number of footers,
# including group footers. ~FatTable~ applies formatting directives to the extent
# they makes sense for the output medium and treats other formatting directives as
# no-ops.
#
# ~FatTable~ can be used to perform operations on data that are naturally best
# conceived of as tables, which in my experience is quite often. It can also
# serve as a foundation for providing reporting functions where flexibility
# about the output medium can be useful. Finally ~FatTable~ can be used within
# Emacs ~org-mode~ files in code blocks targeting the Ruby language. Org mode
# tables are presented to a ruby code block as an array of arrays, so ~FatTable~
# can read them in with its ~.from_aoa~ constructor. A ~FatTable~ table output as an
# array of arrays with its ~.to_aoa~ output function will be rendered in an
# org-mode buffer as an org-table, ready for processing by other code blocks.
module FatTable
  require 'fat_core/symbol'
  require 'fat_core/array'
  require 'fat_core/hash'
  require 'fat_core/numeric'
  require 'ostruct'
  require 'csv'
  require 'sequel'
  require 'active_support'
  require 'active_support/core_ext'
  require 'active_support/number_helper'

  require 'core_ext'
  require 'fat_table/version'
  require 'fat_table/patches'
  require 'fat_table/evaluator'
  require 'fat_table/convert'
  require 'fat_table/column'
  require 'fat_table/table'
  require 'fat_table/footer'
  require 'fat_table/formatters'
  require 'fat_table/db_handle'
  require 'fat_table/errors'

  # Add paths for common db gems to the load paths
  %w[pg mysql2 sqlite].each do |gem_name|
    path = Dir.glob("#{ENV['GEM_HOME']}/gems/#{gem_name}*").sort.last
    if path
      path = File.join(path, 'lib')
      $LOAD_PATH << path unless $LOAD_PATH.include?(path)
    end
  end

  # Valid output formats as symbols.
  FORMATS = %i[psv aoa aoh latex org term text].freeze

  class << self
    # Set a default output format to use when FatTable.to_format is invoked.
    # Valid formats are +:psv+, +:aoa+, +:aoh+, +:latex+, +:org+, +:term+, and
    # +:text+, or their string equivalents. By default, +FatTable.format+ is
    # +:text+.
    attr_accessor :format

    # Default value to use to indicate currency in a Numeric column.  By default
    # this is set to '$'.
    attr_accessor :currency_symbol
  end
  self.format = :text
  self.currency_symbol = '$'

  ###########################################################################
  # Table Constructors
  ###########################################################################

  # Return an empty FatTable::Table object. You can use FatTable::Table#add_row
  # or FatTable::Table#add_column to populate the table with data.
  def self.new(*args, **types)
    Table.new(*args, **types)
  end

  # Construct a FatTable::Table from the contents of a CSV file given by the
  # file name +fname+. Headers will be taken from the first row and converted to
  # symbols.
  def self.from_csv_file(fname, **types)
    Table.from_csv_file(fname, **types)
  end

  # Construct a FatTable::Table from the string +str+, treated in the same
  # manner as if read the input from a CSV file. Headers will be taken from the
  # first row and converted to symbols.
  def self.from_csv_string(str, **types)
    Table.from_csv_string(str, **types)
  end

  # Construct a FatTable::Table from the first table found in the Emacs org-mode
  # file names +fname+. Headers are taken from the first row if the second row
  # is an hline. Otherwise, synthetic headers of the form +:col_1+, +:col_2+,
  # etc. are created. Any other hlines will be treated as marking a boundary in
  # the table.
  def self.from_org_file(fname, **types)
    Table.from_org_file(fname, **types)
  end

  # Construct a FatTable::Table from the first table found in the string +str+,
  # treated in the same manner as if read from an Emacs org-mode file. Headers
  # are taken from the first row if the second row is an hrule. Otherwise,
  # synthetic headers of the form :col_1, :col_2, etc. are created. Any other
  # hlines will be treated as marking a boundary in the table.
  def self.from_org_string(str, **types)
    Table.from_org_string(str, **types)
  end

  # Construct a FatTable::Table from the array of arrays +aoa+. By default, with
  # +hlines+ false, do not look for nil separators, just treat the first row as
  # headers. With +hlines+ true, expect separators to mark the header row and
  # any boundaries. If the second element of the array is a nil, interpret the
  # first element of the array as a row of headers. Otherwise, synthesize
  # headers of the form +:col_1+, +:col_2+, ... and so forth. The remaining
  # elements are taken as the body of the table, except that if an element of
  # the outer array is a nil, mark the preceding row as a boundary. In Emacs
  # org-mode code blocks, by default (+:hlines no+) all hlines are stripped from
  # the table, otherwise (+:hlines yes+) they are indicated with nil elements in
  # the outer array.
  def self.from_aoa(aoa, hlines: false, **types)
    Table.from_aoa(aoa, hlines: hlines, **types)
  end

  # Construct a FatTable::Table from the array of hashes +aoh+, which can be an
  # array of any objects that respond to the #to_h method. With +hlines+ true,
  # interpret nil separators as marking boundaries in the new Table. All hashes
  # must have the same keys, which, converted to symbols, become the headers for
  # the new Table.
  def self.from_aoh(aoh, hlines: false, **types)
    Table.from_aoh(aoh, hlines: hlines, **types)
  end

  # Construct a FatTable::Table from another FatTable::Table. Inherit any group
  # boundaries from the input table.
  def self.from_table(table)
    Table.from_table(table)
  end

  # Construct a Table by running a SQL query against the database set up with
  # FatTable.connect. Return the Table with the query results as rows and the
  # headers from the query, converted to symbols, as headers.
  def self.from_sql(query, **types)
    Table.from_sql(query, **types)
  end

  ########################################################################
  # Formatter
  ########################################################################

  # Return a string or ruby object formatting +table+ according to the format
  # specified in +FatTable.format+. If a block is given, it will yield a
  # +FatTable::Formatter+ of the appropriate type on which formatting and footer
  # methods can be called. If no block is given, the default format for the type
  # will be used. The +options+ are passed along to the FatTable::Formatter
  # created to process the output.
  def self.to_format(table, **options) # :yields: formatter
    if block_given?
      to_any(format, table, **options, &Proc.new)
    else
      to_any(format, table, **options)
    end
  end

  # Return a string or ruby object according to the format given in the +fmt+
  # argument. Valid formats are :psv, :aoa, :aoh, :latex, :org, :term, :text, or
  # their string equivalents. If a block is given, it will yield a
  # +FatTable::Formatter+ of the appropriate type on which formatting and footer
  # methods can be called. If no block is given, the default format for the
  # +fmt+ type will be used.
  def self.to_any(fmt, table, **options)
    fmt = fmt.as_sym
    raise UserError, "unknown format '#{fmt}'" unless FORMATS.include?(fmt)

    method = "to_#{fmt}"
    if block_given?
      send(method, table, **options, &Proc.new)
    else
      send(method, table, **options)
    end
  end

  # Return the +table+ as a string formatted as pipe-separated values, passing
  # the +options+ to a new +FatTable::Formatter+ object. If no block is given,
  # default formatting is applied to the +table+'s cells. If a block is given,
  # it yields the +FatTable::Formatter+ to the block on which formatting
  # and footer methods can be called.
  def self.to_psv(table, **options)
    fmt = Formatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as an Array of Array of strings. If no block is given,
  # default formatting is applies to the table's cells. If a block is given, it
  # yields an AoaFormatter to the block to which formatting instructions and
  # footers can be added by calling methods on it.
  def self.to_aoa(table, **options)
    fmt = AoaFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as an Array of Hashes. Each inner hash uses the Table's
  # columns as keys and it values are strings representing the cells of the
  # table. If no block is given, default formatting is applies to the table's
  # cells. If a block is given, it yields an AohFormatter to the block to which
  # formatting instructions and footers can be added by calling methods on it.
  def self.to_aoh(table, **options)
    fmt = AohFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing a LaTeX table. If no block is given,
  # default formatting applies to the table's cells. If a block is given, it
  # yields a LaTeXFormatter to the block to which formatting instructions and
  # footers can be added by calling methods on it.
  def self.to_latex(table, **options)
    fmt = LaTeXFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing an Emacs org-mode table. If no block
  # is given, default formatting applies to the table's cells. If a block is
  # given, it yields a OrgFormatter to the block to which formatting
  # instructions and footers can be added by calling methods on it.
  def self.to_org(table, **options)
    fmt = OrgFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing ANSI terminal text representing
  # table. If no block is given, default formatting applies to the table's
  # cells. If a block is given, it yields a TermFormatter to the block to which
  # formatting instructions and footers can be added by calling methods on it.
  def self.to_term(table, **options)
    fmt = TermFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing ordinary text representing table. If
  # no block is given, default formatting applies to the table's cells. If a
  # block is given, it yields a TextFormatter to the block to which formatting
  # instructions and footers can be added by calling methods on it.
  def self.to_text(table, **options)
    fmt = TextFormatter.new(table, **options)
    yield fmt if block_given?
    fmt.output
  end
end
