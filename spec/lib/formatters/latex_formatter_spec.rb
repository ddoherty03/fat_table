require 'spec_helper'
require 'tempfile'

module FatCore
  describe LaTeXFormatter do
    describe 'table output' do
      before :all do
      end

      before :each do
        @aoa =
          [['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
           nil,
           [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1 $100', 'T'],
           [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1', 'T'],
           [5, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1\'s "Ent"', 'T'],
           [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ZMEAC', 'F'],
           [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ZMEAC', 'T'],
           [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ZMEAC', 'T'],
           [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ZMEAC', 'T'],
           [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ZMEAC', 'F'],
           [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ZMEAC', 'T'],
           [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ZMEAC', 'T'],
           [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ZMEAC', 'F'],
           [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ZMEAC', 'T'],
           [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']]
        @tab = Table.from_aoa(@aoa).order_by(:date)
        @ltxcmd = '/usr/bin/pdflatex -interaction nonstopmode'
      end

      it 'should raise an error for an invalid color' do
        expect {
        LaTeXFormatter.new(@tab) do |f|
          f.format_for(:body, date: 'c[Yeller]')
        end
        }.to raise_error(/invalid color 'Yeller'/)
      end

      it 'should be able to output valid LaTeX with default formatting instructions' do
        tmp = File.open("#{__dir__}/../../tmp/example1.tex", 'w')
        ltx = LaTeXFormatter.new(@tab).output
        result = false
        Dir.chdir(File.dirname(tmp.path)) do
          tmp << "\\documentclass{article}\n"
          tmp << LaTeXFormatter.preamble
          tmp << "\\begin{document}\n"
          tmp << ltx
          tmp << "\\end{document}\n"
          tmp.flush
          result = system("#{@ltxcmd} #{tmp.path} >/dev/null 2>&1")
          result &&= system("#{@ltxcmd} #{tmp.path} >/dev/null 2>&1")
        end
        expect(ltx.class).to eq(String)
        expect(result).to be true
      end

      it 'should be able to set format and output LaTeX with block' do
        fmt = LaTeXFormatter.new(@tab) do |f|
          f.format(ref: '5.0', code: 'C', raw: ',0.0', shares: ',0.0',
                   price: '0.3R', bool: 'CYc[green,red]', numeric: 'Rc[Goldenrod1]')
          f.format_for(:header, string: 'CB')
          f.format_for(:footer, string: 'B')
          f.sum_gfooter(:price, :raw, :shares)
          f.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
          f.format_for(:gfooter, ref: 'LIBc[Tomato1]')
          f.sum_footer(:price, :raw, :shares)
          f.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
          f.footer('Any?', bool: :any?)
          f.format_for(:footer, ref: 'LBc[Blue2]')
        end
        ltx = fmt.output
        expect(ltx.class).to eq(String)
        expect(ltx).to match(/\bRef\b/)
        expect(ltx).to match(/\bBool\b/)
        expect(ltx).to match(/\b2013-05-02\b/)
        expect(ltx).to match(/\D795,546\D/)
        expect(ltx).to match(/\D1,031,919\D/)
        expect(ltx).to match(/\D1.185\D/)
        expect(ltx).to match(/\D24.885\D/)
        expect(ltx).to match(/\D00001\D/)
        expect(ltx).to match(/\bY\b/)
        expect(ltx).to match(/\bP\b/)
        expect(ltx).to match(/\bZMPEF1\b/)
        expect(ltx).to match(/\bGroup Total\b/)
        expect(ltx).to match(/\bGrp Std Dev\b/)
        tmp = File.open("#{__dir__}/../../tmp/example2.tex", 'w')
        result = false
        Dir.chdir(File.dirname(tmp.path)) do
          tmp << "\\documentclass{article}\n"
          tmp << LaTeXFormatter.preamble
          tmp << "\\usepackage{geometry}\n"
          tmp << "\\geometry{left=0.5in,right=0.5in}\n"
          tmp << "\\begin{document}\n"
          tmp << "\\begin{center}\n"
          tmp << "\\begin{small}\n"
          tmp << ltx
          tmp << "\\end{small}\n"
          tmp << "\\end{center}\n"
          tmp << "\\end{document}\n"
          tmp.flush
          result = system("#{@ltxcmd} #{tmp.path} >/dev/null 2>&1")
          result &&= system("#{@ltxcmd} #{tmp.path} >/dev/null 2>&1")
        end
        expect(result).to be true
      end
    end
  end
end
