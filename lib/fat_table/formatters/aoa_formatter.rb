module FatTable
  # A subclass of Formatter for rendering the table as a Ruby Array of Arrays.
  # Each cell is formatted as a string in accordance with the formatting
  # directives. All footers are included as extra Arrays of the output.
  # AoaFormatter supports no +options+
  class AoaFormatter < Formatter
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

    def pre_header(_widths)
      ''
    end

    def post_header(_widths)
      ''
    end

    def pre_row
      '['
    end

    def pre_cell(_h)
      "'"
    end

    # Because the cell, after conversion to a single-quoted string will be
    # eval'ed, we need to escape any single-quotes (') that appear in the
    # string.
    def quote_cell(v)
      if v.match?(/'/)
        # Use a negative look-behind to only quote single-quotes that are not
        # already preceded by a backslash
        v.gsub(/(?<!\\)'/, "'" => "\\'")
      else
        v
      end
    end

    def post_cell
      "'"
    end

    def inter_cell
      ','
    end

    def post_row
      "],\n"
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
