module FatCore
  # Output the table as plain text. This is almost identical to OrgFormatter
  # except that dates do not get formatted as inactive timestamps and the
  # connector at the beginning of hlines is a '+' rather than a '|' as for org
  # tables.
  class TextFormatter < Formatter
    # Does this Formatter require a second pass over the cells to align the
    # columns according to the alignment formatting instruction to the width of
    # the widest cell in each column?
    def aligned?
      true
    end

    def pre_header(widths)
      result = '+'
      widths.values.each do |w|
        result += '=' * (w + 2) + '+'
      end
      result[-1] = '+'
      result + "\n"
    end

    def pre_row
      '|'
    end

    def pre_cell(_h)
      ''
    end

    def quote_cell(v)
      v
    end

    def post_cell
      ''
    end

    def inter_cell
      '|'
    end

    def post_row
      "|\n"
    end

    def hline(widths)
      result = '+'
      widths.values.each do |w|
        result += '-' * (w + 2) + '+'
      end
      result[-1] = '+'
      result + "\n"
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

    def post_footers(widths)
      result = '+'
      widths.values.each do |w|
        result += '=' * (w + 2) + '+'
      end
      result[-1] = '+'
      result + "\n"
    end
  end
end
