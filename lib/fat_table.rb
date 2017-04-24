require "fat_table/version"

module FatTable
  require 'fat_core'
  require 'dbi'
  require 'active_support'
  require 'active_support/core_ext'
  require 'active_support/number_helper'

  require 'fat_table/evaluator'
  require 'fat_table/column'
  require 'fat_table/table'
  require 'fat_table/formatters'
  require 'fat_table/db_handle'
  require 'fat_table/errors'

  ###########################################################################
  # Table Constructors
  ###########################################################################

  # Return an empty FatTable::Table object.  You can use add_row or add_column
  # to fill on the table.
  def self.new
    Table.new
  end

  # Construct a FatTable::Table from the contents of a CSV file. Headers will be
  # taken from the first row and converted to symbols.
  def self.from_csv_file(fname)
    Table.from_csv_file(fname)
  end

  # Construct a FatTable::Table from a string, treated in the same manner as if
  # read the input from a CSV file. Headers will be taken from the first row and
  # converted to symbols.
  def self.from_csv_string(str)
    Table.from_csv_string(str)
  end

  # Construct a FatTable::Table from the first table found in the given Emacs
  # org-mode file. Headers are taken from the first row if the second row is an
  # hrule. Otherwise, synthetic headers of the form :col_1, :col_2, etc. are
  # created. Any other hlines will be treated as marking a boundary in the
  # table.
  def self.from_org_file(fname)
    Table.from_org_file(fname)
  end

  # Construct a FatTable::Table from the first table found in the given string,
  # treated in the same manner as if read from an Emacs org-mode file. Headers
  # are taken from the first row if the second row is an hrule. Otherwise,
  # synthetic headers of the form :col_1, :col_2, etc. are created. Any other
  # hlines will be treated as marking a boundary in the table.
  def self.from_org_string(str)
    Table.from_org_string(str)
  end

  # Construct a FatTable::Table from an array of arrays. By default, with hlines
  # false, do not look for separators, i.e. nil or a string of dashes, just
  # treat the first row as headers. With hlines true, expect separators to mark
  # the header row and any boundaries. If the second element of the array is a
  # nil, or an array whose first element is a string that looks like an hrule,
  # '|-----------', '+----------', etc., interpret the first element of the
  # array as a row of headers. Otherwise, synthesize headers of the form :col_1,
  # :col_2, ... and so forth. The remaining elements are taken as the body of
  # the table, except that if an element of the outer array is a nil or an array
  # whose first element is a string that looks like an hrule, mark the preceding
  # row as a boundary. In org mode code blocks, by default (:hlines no) all
  # hlines are stripped from the table, otherwise (:hlines yes) they are
  # indicated with nil elements in the outer array.
  def self.from_aoa(aoa, hlines: false)
    Table.from_aoa(aoa, hlines: hlines)
  end

  # Construct a FatTable::Table from an array of hashes, or an array of any
  # objects that respond to the #to_h method. All hashes must have the same
  # keys, which, converted to symbols, will become the headers for the Table.
  def self.from_aoh(aoh, hlines: false)
    Table.from_aoh(aoh, hlines: hlines)
  end

  # Construct a FatTable::Table from another FatTable::Table. Inherit any group
  # boundaries from the input table.
  def self.from_table(table)
    Table.from_table(table)
  end

  # Construct a Table by running a SQL query against the database set up with
  # FatTable.set_db.  Return the Table with the query results as rows.
  def self.from_sql(query)
    Table.from_sql(query)
  end

  ########################################################################
  # Formatter
  ########################################################################

  FORMATS = [:psv, :aoa, :aoh, :latex, :org, :term, :text].freeze

  # Set a default output format to use when FatTable.to_format is invoked.
  class << self
    attr_accessor :format
  end
  self.format = :text

  # Return a string or ruby object according to the format specified in
  # FatTable.format.  If a block is given, it will yield a Formatter of the
  # appropriate type to which format and footers can be applied. Otherwise, the
  # default format for the type will be used.
  def self.to_format(table, options = {})
    if block_given?
      to_any(format, table, options, &Proc.new)
    else
      to_any(format, table, options)
    end
  end

  # Return a string or ruby object according to the format given in the first
  # argument. Valid formats are :psv, :aoa, :aoh, :latex, :org, :term, :text, or
  # their string equivalents. If a block is given, it will yield a Formatter of
  # the appropriate type to which format and footers can be applied. Otherwise,
  # the default format for the type will be used.
  def self.to_any(fmt, table, options = {})
    fmt = fmt.as_sym
    raise UserError, "unknown format '#{fmt}'" unless FORMATS.include?(fmt)
    method = "to_#{fmt}"
    if block_given?
      send method, table, options, &Proc.new
    else
      send method, table, options
    end
  end

  # Return the table as a string formatted as a pipe-separated values. If no
  # block is given, default formatting is applies to the table's cells. If a
  # block is given, it yields a Formatter to the block to which formatting
  # instructions and footers can be added by calling methods on it.
  def self.to_psv(table, options = {})
    fmt = Formatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as an Array of Array of strings. If no block is given,
  # default formatting is applies to the table's cells. If a block is given, it
  # yields an AoaFormatter to the block to which formatting instructions and
  # footers can be added by calling methods on it.
  def self.to_aoa(table, options = {})
    fmt = AoaFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as an Array of Hashes. Each inner hash uses the Table's
  # columns as keys and it values are strings representing the cells of the
  # table. If no block is given, default formatting is applies to the table's
  # cells. If a block is given, it yields an AohFormatter to the block to which
  # formatting instructions and footers can be added by calling methods on it.
  def self.to_aoh(table, options = {})
    fmt = AohFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing a LaTeX table. If no block is given,
  # default formatting applies to the table's cells. If a block is given, it
  # yields a LaTeXFormatter to the block to which formatting instructions and
  # footers can be added by calling methods on it.
  def self.to_latex(table, options = {})
    fmt = LaTeXFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing an Emacs org-mode table. If no block
  # is given, default formatting applies to the table's cells. If a block is
  # given, it yields a OrgFormatter to the block to which formatting
  # instructions and footers can be added by calling methods on it.
  def self.to_org(table, options = {})
    fmt = OrgFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing ANSI terminal text representing
  # table. If no block is given, default formatting applies to the table's
  # cells. If a block is given, it yields a TermFormatter to the block to which
  # formatting instructions and footers can be added by calling methods on it.
  def self.to_term(table, options = {})
    fmt = TermFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end

  # Return the table as a string containing ordinary text representing table. If
  # no block is given, default formatting applies to the table's cells. If a
  # block is given, it yields a TextFormatter to the block to which formatting
  # instructions and footers can be added by calling methods on it.
  def self.to_text(table, options = {})
    fmt = TextFormatter.new(table, options)
    yield fmt if block_given?
    fmt.output
  end
end
