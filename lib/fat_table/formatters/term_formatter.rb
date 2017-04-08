# -*- coding: utf-8 -*-

require 'rainbow'

module FatCore
  # Output the table as for a unicode-enabled terminal.  This makes table
  # gridlines drawable with unicode characters, as well as supporting colored
  # text and backgrounds.plain text.

  class TermFormatter < Formatter
    def initialize(table = Table.new, **options)
      super
      @options[:unicode] = options.fetch(:unicode, true)
      @options[:framecolor] = options.fetch(:framecolor, 'none.none')
      if @options[:framecolor] =~ /([-_a-zA-Z]*)(\.([-_a-zA-Z]*))/
        @options[:frame_fg] = $1.downcase unless $1.blank?
        @options[:frame_bg] = $3.downcase unless $3.blank?
      end
    end

    # Taken from the xcolor documentation PDF, list of base colors and x11names.
    self.valid_colors = ['none'] + Rainbow::X11ColorNames::NAMES.keys.map(&:to_s).sort

    def color_valid?(clr)
      valid_colors.include?(clr)
    end

    def invalid_color_msg(clr)
      valid_colors_list = valid_colors.join(' ').wrap
      "TermFormatter invalid color '#{clr}'. Valid colors are:\n#{valid_colors_list}"
    end
    # Compute the width of the string as displayed, taking into account the
    # characteristics of the target device.  For example, a colored string
    # should not include in the width terminal control characters that simply
    # change the color without occupying any space.  Thus, this method must be
    # overridden in a subclass if a simple character count does not reflect the
    # width as displayed.
    def width(str)
      strip_ansi(str).length
    end

    def strip_ansi(str)
      str.gsub(/\e\[[0-9;]+m/, '') if str
    end

    # Add ANSI codes to string to implement the given decorations
    def decorate_string(str, istruct)
      result = Rainbow(str)
      result = colorize(result, istruct.color, istruct.bgcolor)
      result = result.bold if istruct.bold
      result = result.italic if istruct.italic
      result = result.underline if istruct.underline
      result = result.blink if istruct.blink
      result
    end

    def colorize(str, fg, bg)
      fg = nil if fg == 'none'
      bg = nil if bg == 'none'
      return str unless fg || bg
      result = Rainbow(str)
      if fg
        fg = fg.tr(' ', '').downcase.as_sym
        result = result.color(fg) if fg
      end
      if bg
        bg = bg.tr(' ', '').downcase.as_sym
        result = result.bg(bg) if bg
      end
      result
    end

    # Colorize frame components
    def frame_colorize(str)
      colorize(str, @options[:frame_fg], @options[:frame_bg])
    end

    # Unicode line-drawing characters. We use double lines before and after the
    # table and single lines for the sides and hlines between groups and
    # footers.
    UPPER_LEFT = "\u2552".freeze
    UPPER_RIGHT = "\u2555".freeze
    DOUBLE_RULE = "\u2550".freeze
    UPPER_TEE = "\u2564".freeze
    VERTICAL_RULE = "\u2502".freeze
    LEFT_TEE = "\u251C".freeze
    HORIZONTAL_RULE = "\u2500".freeze
    SINGLE_CROSS = "\u253C".freeze
    RIGHT_TEE = "\u2524".freeze
    LOWER_LEFT = "\u2558".freeze
    LOWER_RIGHT = "\u255B".freeze
    LOWER_TEE = "\u2567".freeze

    def upper_left
      if options[:unicode]
        UPPER_LEFT
      else
        '+'
      end
    end

    def upper_right
      if options[:unicode]
        UPPER_RIGHT
      else
        '+'
      end
    end

    def double_rule
      if options[:unicode]
        DOUBLE_RULE
      else
        '='
      end
    end

    def upper_tee
      if options[:unicode]
        UPPER_TEE
      else
        '+'
      end
    end

    def vertical_rule
      if options[:unicode]
        VERTICAL_RULE
      else
        '|'
      end
    end

    def left_tee
      if options[:unicode]
        LEFT_TEE
      else
        '+'
      end
    end

    def horizontal_rule
      if options[:unicode]
        HORIZONTAL_RULE
      else
        '-'
      end
    end

    def single_cross
      if options[:unicode]
        SINGLE_CROSS
      else
        '+'
      end
    end

    def right_tee
      if options[:unicode]
        RIGHT_TEE
      else
        '+'
      end
    end

    def lower_left
      if options[:unicode]
        LOWER_LEFT
      else
        '+'
      end
    end

    def lower_right
      if options[:unicode]
        LOWER_RIGHT
      else
        '+'
      end
    end

    def lower_tee
      if options[:unicode]
        LOWER_TEE
      else
        '+'
      end
    end

    # Does this Formatter require a second pass over the cells to align the
    # columns according to the alignment formatting instruction to the width of
    # the widest cell in each column?
    def aligned?
      true
    end

    def pre_header(widths)
      result = upper_left
      widths.values.each do |w|
        result += double_rule * (w + 2) + upper_tee
      end
      result[-1] = upper_right
      result = colorize(result, @options[:frame_fg], @options[:frame_bg])
      result + "\n"
    end

    def pre_row
      frame_colorize(vertical_rule)
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
      frame_colorize(vertical_rule)
    end

    def post_row
      frame_colorize(vertical_rule) + "\n"
    end

    def hline(widths)
      result = left_tee
      widths.values.each do |w|
        result += horizontal_rule * (w + 2) + single_cross
      end
      result[-1] = right_tee
      result = frame_colorize(result)
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
      result = lower_left
      widths.values.each do |w|
        result += double_rule * (w + 2) + lower_tee
      end
      result[-1] = lower_right
      result = frame_colorize(result)
      result + "\n"
    end
  end
end
