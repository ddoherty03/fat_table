module FatCore
  # Output the table as plain text. This is almost identical to OrgFormatter
  # except that dates do not get formatted as inactive timestamps and the
  # connector at the beginning of hlines is a '+' rather than a '|' as for org
  # tables. i

  class LaTeXFormatter < Formatter

    # Taken from the xcolor documentation PDF, list of base colors and x11names.
    self.valid_colors = %w(
    none black blue brown cyan darkgray gray green lightgray
    lime magenta olive orange pink purple red teal violet white yellow
    AntiqueWhite1 AntiqueWhite2 AntiqueWhite3 AntiqueWhite4 Aquamarine1
    Aquamarine2 Aquamarine3 Aquamarine4 Azure1 Azure2 Azure3 Azure4 Bisque1
    Bisque2 Bisque3 Bisque4 Blue1 Blue2 Blue3 Blue4 Brown1 Brown2 Brown3 Brown4
    Burlywood1 Burlywood2 Burlywood3 Burlywood4 CadetBlue1 CadetBlue2 CadetBlue3
    CadetBlue4 Chartreuse1 Chartreuse2 Chartreuse3 Chartreuse4 Chocolate1
    Chocolate2 Chocolate3 Chocolate4 Coral1 Coral2 Coral3 Coral4 Cornsilk1
    Cornsilk2 Cornsilk3 Cornsilk4 Cyan1 Cyan2 Cyan3 Cyan4 DarkGoldenrod1
    DarkGoldenrod2 DarkGoldenrod3 DarkGoldenrod4 DarkOliveGreen1 DarkOliveGreen2
    DarkOliveGreen3 DarkOliveGreen4 DarkOrange1 DarkOrange2 DarkOrange3
    DarkOrange4 DarkOrchid1 DarkOrchid2 DarkOrchid3 DarkOrchid4 DarkSeaGreen1
    DarkSeaGreen2 DarkSeaGreen3 DarkSeaGreen4 DarkSlateGray1 DarkSlateGray2
    DarkSlateGray3 DarkSlateGray4 DeepPink1 DeepPink2 DeepPink3 DeepPink4
    DeepSkyBlue1 DeepSkyBlue2 DeepSkyBlue3 DeepSkyBlue4 DodgerBlue1 DodgerBlue2
    DodgerBlue3 DodgerBlue4 Firebrick1 Firebrick2 Firebrick3 Firebrick4 Gold1
    Gold2 Gold3 Gold4 Goldenrod1 Goldenrod2 Goldenrod3 Goldenrod4 Gray0 Green0
    Green1 Green2 Green3 Green4 Grey0 Honeydew1 Honeydew2 Honeydew3 Honeydew4
    HotPink1 HotPink2 HotPink3 HotPink4 IndianRed1 IndianRed2 IndianRed3
    IndianRed4 Ivory1 Ivory2 Ivory3 Ivory4 Khaki1 Khaki2 Khaki3 Khaki4
    LavenderBlush1 LavenderBlush2 LavenderBlush3 LavenderBlush4 LemonChiffon1
    LemonChiffon2 LemonChiffon3 LemonChiffon4 LightBlue1 LightBlue2 LightBlue3
    LightBlue4 LightCyan1 LightCyan2 LightCyan3 LightCyan4 LightGoldenrod1
    LightGoldenrod2 LightGoldenrod3 LightGoldenrod4 LightPink1 LightPink2
    LightPink3 LightPink4 LightSalmon1 LightSalmon2 LightSalmon3 LightSalmon4
    LightSkyBlue1 LightSkyBlue2 LightSkyBlue3 LightSkyBlue4 LightSteelBlue1
    LightSteelBlue2 LightSteelBlue3 LightSteelBlue4 LightYellow1 LightYellow2
    LightYellow3 LightYellow4 Magenta1 Magenta2 Magenta3 Magenta4 Maroon0
    Maroon1 Maroon2 Maroon3 Maroon4 MediumOrchid1 MediumOrchid2 MediumOrchid3
    MediumOrchid4 MediumPurple1 MediumPurple2 MediumPurple3 MediumPurple4
    MistyRose1 MistyRose2 MistyRose3 MistyRose4 NavajoWhite1 NavajoWhite2
    NavajoWhite3 NavajoWhite4 OliveDrab1 OliveDrab2 OliveDrab3 OliveDrab4
    Orange1 Orange2 Orange3 Orange4 OrangeRed1 OrangeRed2 OrangeRed3 OrangeRed4
    Orchid1 Orchid2 Orchid3 Orchid4 PaleGreen1 PaleGreen2 PaleGreen3 PaleGreen4
    PaleTurquoise1 PaleTurquoise2 PaleTurquoise3 PaleTurquoise4 PaleVioletRed1
    PaleVioletRed2 PaleVioletRed3 PaleVioletRed4 PeachPuff1 PeachPuff2
    PeachPuff3 PeachPuff4 Pink1 Pink2 Pink3 Pink4 Plum1 Plum2 Plum3 Plum4
    Purple0 Purple1 Purple2 Purple3 Purple4 Red1 Red2 Red3 Red4 RosyBrown1
    RosyBrown2 RosyBrown3 RosyBrown4 RoyalBlue1 RoyalBlue2 RoyalBlue3 RoyalBlue4
    Salmon1 Salmon2 Salmon3 Salmon4 SeaGreen1 SeaGreen2 SeaGreen3 SeaGreen4
    Seashell1 Seashell2 Seashell3 Seashell4 Sienna1 Sienna2 Sienna3 Sienna4
    SkyBlue1 SkyBlue2 SkyBlue3 SkyBlue4 SlateBlue1 SlateBlue2 SlateBlue3
    SlateBlue4 SlateGray1 SlateGray2 SlateGray3 SlateGray4 Snow1 Snow2 Snow3
    Snow4 SpringGreen1 SpringGreen2 SpringGreen3 SpringGreen4 SteelBlue1
    SteelBlue2 SteelBlue3 SteelBlue4 Tan1 Tan2 Tan3 Tan4 Thistle1 Thistle2
    Thistle3 Thistle4 Tomato1 Tomato2 Tomato3 Tomato4 Turquoise1 Turquoise2
    Turquoise3 Turquoise4 VioletRed1 VioletRed2 VioletRed3 VioletRed4 Wheat1
    Wheat2 Wheat3 Wheat4 Yellow1 Yellow2 Yellow3 Yellow4)
    def color_valid?(clr)
      valid_colors.include?(clr)
    end

    def invalid_color_msg(clr)
      valid_colors_list = valid_colors.join(' ').wrap
      "LaTeXFormatter invalid color '#{clr}'. Valid colors are:\n#{valid_colors_list}"
    end

    # Add LaTeX control sequences. Ignore background color, underline, and
    # blink. Alignment needs to be done by LaTeX, so we have to take it into
    # account unless it's the same as the body alignment, since that is the
    # default.
    def decorate_string(str, istruct)
      str = quote_for_decorate(str)
      result = ''
      result += '\\bfseries{}' if istruct.bold
      result += '\\itshape{}' if istruct.italic
      result += "\\color{#{istruct.color}}" if istruct.color && istruct.color != 'none'
      result = "#{result}#{str}"
      unless istruct.alignment == format_at[:body][istruct._h].alignment
        ac = alignment_code(istruct.alignment)
        result = "\\multicolumn{1}{#{ac}}{#{result}}"
      end
      result
    end

    def quote_for_decorate(str)
      result = str.gsub(/'([^']*)'/, "`\\1'")
      result = result.gsub(/"([^"]*)"/, "``\\1''")
      result.tex_quote
    end

    def self.preamble
      "\\usepackage{longtable}\n
      \\usepackage[pdftex,x11names]{xcolor}\n"
    end

    def pre_table
      result = '\\begin{longtable}{'
      table.headers.each do |h|
        result += alignment_code(format_at[:body][h].alignment)
      end
      result += "}\n"
      result
    end

    def alignment_code(al_sym)
      case al_sym
      when :center
        'c'
      when :right
        'r'
      else
        'l'
      end
    end

    def post_table
      "\\end{longtable}\n"
    end

    def post_header(_widths)
      "\\endhead\n"
    end

    def pre_row
      ''
    end

    def pre_cell(_h)
      ''
    end

    # We do quoting before applying decoration, so do not re-quote here.  We
    # will have LaTeX commands in v.
    def quote_cell(v)
      v
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
    def hline(widths)
      ''
    end

    # Hlines look to busy in a printed table
    def post_footers(widths)
      '' #"\\hline\\hline\n"
    end
  end
end
