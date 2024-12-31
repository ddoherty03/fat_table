# frozen_string_literal: true

module FatTable
  # A subclass of Formatter for rendering the table as a Ruby Array of Hashes.
  # Each row of the Array is a Hash representing one row of the table with the
  # keys being the symbolic form of the headers. Each cell is a value in a row
  # Hash formatted as a string in accordance with the formatting directives. All
  # footers are included as extra Hashes of the output. AoaFormatter supports no
  # +options+
  class AohFormatter < Formatter
    private

    def evaluate?
      true
    end

    def pre_table
      '['
    end

    def post_table
      ']'
    end

    # We include no row for the header because the keys of each hash serve as
    # the headers.
    def include_header_row?
      false
    end

    def pre_row
      '{'
    end

    def pre_cell(head)
      ":#{head.as_sym} => '"
    end

    # Because the cell, after conversion to a single-quoted string will be
    # eval'ed, we need to escape any single-quotes (') that appear in the
    # string.
    def quote_cell(val)
      if val.include?("'")
        # Use a negative look-behind to only quote single-quotes that are not
        # already preceded by a backslash
        val.gsub(/(?<!\\)'/, "'" => "\\'")
      else
        val
      end
    end

    def post_cell
      "'"
    end

    def inter_cell
      ','
    end

    def post_row
      "},\n"
    end

    def hline(_widths)
      "nil,\n"
    end

    def pre_group
      ''
    end

    def post_group
      ''
    end

    def pre_gfoot
      ''
    end

    def post_gfoot
      ''
    end

    def pre_foot
      ''
    end

    def post_foot
      ''
    end
  end
end
