# frozen_string_literal: true

module FatTable
  # A subclass of Formatter for rendering the table as a LaTeX table. It allows
  # foreground colors through LaTeX's xcolor package but ignores background
  # colors.  You can see the valid color names with LaTeXFormatter.valid_colors.
  class LaTeXFormatter < Formatter
    # Return a new LaTeXFormatter for +table+.  You can set the following
    # +options+ with hash-like parameters:
    #
    # document::
    #   if set to true, include a document preamble and wrap the output in a
    #   LaTeX document environment so that the output can be compiled by a LaTeX
    #   processor such as +pdflatex+.  By default, only the table environment is
    #   output.
    #
    # environment::
    #   set to a string, by default 'longtable' that indicates what kind of
    #   LaTeX tabular-like environment to use for the table. The default is good
    #   for tables that might continue over multiple pages since it repeats the
    #   header at the top of each continuation page.
    def initialize(table = Table.new, **options)
      super
      @options[:document] = options.fetch(:document, false)
      @options[:environment] = options.fetch(:environment, 'longtable')
    end

    # Taken from the Rainbow gem's list of valid colors.

    self.valid_colors = File.readlines(File.join(__dir__, 'xcolors.txt'), chomp: true)

    # LaTeX commands to load the needed packages based on the :environement
    # option.  For now, just handles the default 'longtable' :environment.  The
    # preamble always includes a command to load the xcolor package.
    def preamble
      result = ''
      result +=
        case @options[:environment]
        when 'longtable'
          "\\usepackage{longtable}\n"
        else
          ''
        end
      result += "\\usepackage[pdftex,table,x11names]{xcolor}\n"
      result
    end

    # Add LaTeX control sequences. Ignore background color, underline, and
    # blink. Alignment needs to be done by LaTeX, so we have to take it into
    # account unless it's the same as the body alignment, since that is the
    # default.
    def decorate_string(str, istruct)
      str = quote(str)
      result = istruct[:italic] ? "\\itshape{#{str}}" : str
      result = istruct[:bold] ? "\\bfseries{#{result}}" : result
      if istruct[:color] && istruct[:color] != 'none'
        result = "{\\textcolor{#{istruct[:color]}}{#{result}}}"
      end
      if istruct[:bgcolor] && istruct[:bgcolor] != 'none'
        result = "{\\cellcolor{#{istruct[:bgcolor]}}{#{result}}}"
      end
      if (istruct[:_h] && format_at[:body][istruct[:_h]] &&
         istruct[:alignment] != format_at[:body][istruct[:_h]][:alignment]) ||
         (istruct[:_h].nil? && istruct[:alignment].to_sym != :left)
        ac = alignment_code(istruct[:alignment])
        result = "\\multicolumn{1}{#{ac}}{#{result}}"
      end
      result
    end

    private

    def color_valid?(clr)
      valid_colors.include?(clr)
    end

    def invalid_color_msg(clr)
      valid_colors_list = valid_colors.join(' ').wrap
      "LaTeXFormatter invalid color '#{clr}'. Valid colors are:\n" +
        valid_colors_list
    end

    # Return +str+ with quote marks oriented and special TeX characters quoted.
    def quote(str)
      # Replace single and double quotes with TeX oriented quotes.
      result = str.gsub(/'([^']*)'/, "`\\1'")
      result = result.gsub(/"([^"]*)"/, "``\\1''")
      # Escape special TeX characters, such as $ and %
      result.tex_quote
    end

    def pre_table
      result = ''
      if @options[:document]
        result += "\\documentclass{article}\n"
        result += preamble
        result += "\\begin{document}\n"
      end
      result += "\\begin{#{@options[:environment]}}{"
      table.headers.each do |h|
        result += alignment_code(format_at[:body][h][:alignment])
      end
      result += "}\n"
      result
    end

    def post_table
      result = "\\end{#{@options[:environment]}}\n"
      result += "\\end{document}\n" if @options[:document]
      result
    end

    def alignment_code(al_sym)
      case al_sym.to_sym
      when :center
        'c'
      when :right
        'r'
      else
        'l'
      end
    end

    def post_header(_widths)
      "\\endhead\n"
    end

    def pre_row
      ''
    end

    def pre_cell(_head)
      ''
    end

    # We do quoting before applying decoration, so do not re-quote here.  We
    # will have LaTeX commands in v.
    def quote_cell(val)
      val
    end

    def post_cell
      ''
    end

    def inter_cell
      "&\n"
    end

    def post_row
      "\\\\\n"
    end

    # Hlines look to busy in a printed table
    def hline(_widths)
      ''
    end

    # Hlines look too busy in a printed table
    def post_footers(_widths)
      ''
    end
  end
end
