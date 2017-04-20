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
  def self.from_aoh(aoh)
    Table.from_aoh(aoh)
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
end
