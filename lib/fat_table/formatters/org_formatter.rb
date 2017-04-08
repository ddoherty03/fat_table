module FatCore
  # Output the table in the same way as org-mode for emacs does. This is almost
  # identical to TextFormatter except that dates do get formatted as inactive
  # timestamps and the connector at the beginning of hlines is a '|' rather than
  # a '+' as for text tables.
  class OrgFormatter < Formatter

    self.default_format = default_format.dup
    self.default_format[:date_fmt] = '[%F]'
    self.default_format[:datetime_fmt] = '[%F %a %H:%M:%S]'

    # Does this Formatter require a second pass over the cells to align the
    # columns according to the alignment formatting instruction to the width of
    # the widest cell in each column?
    def aligned?
      true
    end

    def pre_header(widths)
      result = '|'
      widths.values.each do |w|
        result += '-' * (w + 2) + '+'
      end
      result[-1] = '|'
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
      result = '|'
      widths.values.each do |w|
        result += '-' * (w + 2) + '+'
      end
      result[-1] = '|'
      result + "\n"
    end

    def post_footers(widths)
      result = '|'
      widths.values.each do |w|
        result += '-' * (w + 2) + '+'
      end
      result[-1] = '|'
      result + "\n"
    end
  end
end
