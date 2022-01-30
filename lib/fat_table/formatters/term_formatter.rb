# frozen_string_literal: true

require 'rainbow'

module FatTable
  # Output the table as for a unicode-enabled ANSI terminal. This makes table
  # gridlines drawable with unicode characters, as well as supporting colored
  # text and backgrounds, and blink, and underline attributes. See
  # TermFormatter.valid_colors for an Array of valid colors that you can use.
  # The extent to which all of these are actually supported depends on your
  # terminal. TermFormatter uses the +rainbow+ gem for forming colored strings.
  # Use a
  class TermFormatter < Formatter
    # Return a new TermFormatter for +table+.  You can set a few +options+ with
    # the following hash-like parameters:
    #
    # unicode::
    #     if set true, use unicode characters to form the frame of the table on
    #     output; if set false, use ASCII characters for the frame.  By default,
    #     this is true.
    #
    # framecolor::
    #     set to a string of the form '<color>' or '<color.color>' to set the
    #     color of the frame or the color and background color.  By default, the
    #     framecolor is set to 'none.none', meaning that the normal terminal
    #     foreground and background colors will be used for the frame.
    def initialize(table = Table.new, **options)
      super
      @options[:unicode] = options.fetch(:unicode, true)
      @options[:framecolor] = options.fetch(:framecolor, 'none.none')
      return unless @options[:framecolor] =~ /(?<co>[-_a-zA-Z]*)(\.(?<bg>[-_a-zA-Z]*))/

      @options[:frame_fg] = Regexp.last_match[:co].downcase unless Regexp.last_match[:co].blank?
      @options[:frame_bg] = Regexp.last_match[:bg].downcase unless Regexp.last_match[:bg].blank?
    end

    # Valid colors for ANSI terminal using the rainbow gem's X11ColorNames.
    self.valid_colors = ['none'] +
                        ::Rainbow::X11ColorNames::NAMES.keys.map(&:to_s).sort

    private

    def color_valid?(clr)
      valid_colors.include?(clr)
    end

    def invalid_color_msg(clr)
      valid_colors_list = valid_colors.join(' ').wrap
      "TermFormatter invalid color '#{clr}'. Valid colors are:\n" +
        valid_colors_list
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
      return '' unless str

      str.gsub(/\e\[[0-9;]+m/, '')
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

    def colorize(str, fg_color, bg_color)
      fg_color = nil if fg_color == 'none'
      bg_color = nil if bg_color == 'none'
      return str unless fg_color || bg_color

      result = Rainbow(str)
      if fg_color
        fg_color = fg_color.tr(' ', '').downcase.as_sym
        result = result.color(fg_color) if fg_color
      end
      if bg_color
        bg_color = bg_color.tr(' ', '').downcase.as_sym
        result = result.bg(bg_color) if bg_color
      end
      result
    end

    # Colorize frame components
    def frame_colorize(str)
      colorize(str, @options[:frame_fg], @options[:frame_bg])
    end

    # :stopdoc:
    # Unicode line-drawing characters. We use double lines before and after the
    # table and single lines for the sides and hlines between groups and
    # footers.
    UPPER_LEFT = "\u2552"
    UPPER_RIGHT = "\u2555"
    DOUBLE_RULE = "\u2550"
    UPPER_TEE = "\u2564"
    VERTICAL_RULE = "\u2502"
    LEFT_TEE = "\u251C"
    HORIZONTAL_RULE = "\u2500"
    SINGLE_CROSS = "\u253C"
    RIGHT_TEE = "\u2524"
    LOWER_LEFT = "\u2558"
    LOWER_RIGHT = "\u255B"
    LOWER_TEE = "\u2567"
    # :startdoc:

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
      result = +upper_left
      widths.each_value do |w|
        result += double_rule * (w + 2) + upper_tee
      end
      result[-1] = upper_right
      result = colorize(result, @options[:frame_fg], @options[:frame_bg])
      result + "\n"
    end

    def pre_row
      frame_colorize(vertical_rule)
    end

    def pre_cell(_head)
      ''
    end

    def quote_cell(val)
      val
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
      result = +left_tee
      widths.each_value do |w|
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
      result = +lower_left
      widths.each_value do |w|
        result += double_rule * (w + 2) + lower_tee
      end
      result[-1] = lower_right
      result = frame_colorize(result)
      result + "\n"
    end
  end
end
