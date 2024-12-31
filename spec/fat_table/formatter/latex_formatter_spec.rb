module FatTable
  RSpec.describe 'Formatter::LaTeXFormatter' do
    describe 'decorate string' do
      it 'obeys a bold directive' do
        istruct = LaTeXFormatter.default_format
        istruct[:bold] = true
        dstr = LaTeXFormatter.new.decorate_string('Words', istruct)
        expect(dstr).to eq("\\bfseries{Words}")
      end

      it 'obeys an italic directive' do
        istruct = LaTeXFormatter.default_format
        istruct[:italic] = true
        dstr = LaTeXFormatter.new.decorate_string('Words, words, words', istruct)
        expect(dstr).to eq("\\itshape{Words, words, words}")
      end

      it 'obeys a color directive' do
        istruct = LaTeXFormatter.default_format
        istruct[:color] = 'Turquoise'
        dstr = LaTeXFormatter.new.decorate_string('Words, words, words', istruct)
        expect(dstr).to eq("{\\textcolor{Turquoise}{Words, words, words}}")
      end

      it 'obeys a bg_color directive' do
        istruct = LaTeXFormatter.default_format
        istruct[:bgcolor] = 'Pink'
        dstr = LaTeXFormatter.new.decorate_string('Words, words, words', istruct)
        expect(dstr).to eq("{\\cellcolor{Pink}{Words, words, words}}")
      end

      it 'obeys an alignment directive' do
        istruct = LaTeXFormatter.default_format
        istruct[:alignment] = 'right'
        dstr = LaTeXFormatter.new.decorate_string('Words, words, words', istruct)
        expect(dstr).to eq("\\multicolumn{1}{r}{Words, words, words}")
        istruct[:alignment] = 'center'
        dstr = LaTeXFormatter.new.decorate_string('Words, words, words', istruct)
        expect(dstr).to eq("\\multicolumn{1}{c}{Words, words, words}")
      end
    end

    describe 'table output' do
      let(:tab) do
        aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          [1,  '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850,  'ZMPEF1 $100',     'T'],
          [2,  '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1',          'T'],
          [5,  '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1\'s "Ent"', 'T'],
          [7,  '2013-05-20', 'S', 12_000.00,  5046.00,   28.2804, 'ZMEAC',           'F'],
          [8,  '2013-05-20', 'S', 85_000.00,  35_742.50, 28.3224, 'ZMEAC',           'T'],
          [9,  '2013-05-20', 'S', 33_302.00,  14_003.49, 28.6383, 'ZMEAC',           'T'],
          [10, '2013-05-23', 'S', 8000.00,    3364.00,   27.1083, 'ZMEAC',           'T'],
          [11, '2013-05-23', 'S', 23_054.00,  9694.21,   26.8015, 'ZMEAC',           'F'],
          [12, '2013-05-23', 'S', 39_906.00,  16_780.47, 25.1749, 'ZMEAC',           'T'],
          [13, '2013-05-29', 'S', 13_459.00,  5659.51,   24.7464, 'ZMEAC',           'T'],
          [14, '2013-05-29', 'S', 15_700.00,  6601.85,   24.7790, 'ZMEAC',           'F'],
          [15, '2013-05-29', 'S', 15_900.00,  6685.95,   24.5802, 'ZMEAC',           'T'],
          [16, '2013-05-30', 'S', 6_679.00,   2808.52,   25.0471, 'ZMEAC',           'T']
        ]
        Table.from_aoa(aoa).order_by(:date)
      end
      let(:ltxcmd) { 'pdflatex -interaction nonstopmode' }

      before do
        tmp_dir = "#{__dir__}/../../tmp"
        FileUtils.mkdir_p(tmp_dir)
        xmpl_name = "#{__dir__}/../../example_files/example1.tex"
        tmp_name = "#{__dir__}/../../tmp/example1.tex"
        FileUtils.cp(xmpl_name, tmp_name)
        xmpl_name = "#{__dir__}/../../example_files/example2.tex"
        tmp_name = "#{__dir__}/../../tmp/example2.tex"
        FileUtils.cp(xmpl_name, tmp_name)
      end

      it 'raises an error for an invalid color' do
        expect {
          LaTeXFormatter.new(tab) do |f|
            f.format_for(:body, date: 'c[Yeller]')
          end
        }.to raise_error(/invalid color 'Yeller'/)
      end

      it 'outputs valid LaTeX with default formatting' do
        tmp = File.open("#{__dir__}/../../tmp/example1.tex", 'w')
        ltx = LaTeXFormatter.new(tab, document: true).output
        result = false
        Dir.chdir(File.dirname(tmp.path)) do
          tmp << ltx
          tmp.flush
          result = system("#{ltxcmd} #{tmp.path} >latex.err 2>&1")
          result &&= system("#{ltxcmd} #{tmp.path} >>latex.err 2>&1")
        end
        expect(ltx.class).to eq(String)
        expect(result).to be true
      end

      it 'is able to set format and output LaTeX with block' do
        fmt = LaTeXFormatter.new(tab, document: true) do |f|
          f.format(
            ref: '5.0',
            code: 'C',
            raw: 'R,0.0',
            shares: 'R,0.0',
            price: '0.3R',
            bool: 'CYc[green,red]',
            numeric: 'Rc[Goldenrod1]',
          )
          f.format_for(:header, string: 'CB')
          f.format_for(:footer, string: 'B')
          f.sum_gfooter(:price, :raw, :shares)
          f.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
          f.format_for(:gfooter, ref: 'LIBc[Tomato1]')
          f.sum_footer(:price, :raw, :shares)
          f.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
          f.footer('Any?', bool: :any?)
          f.format_for(:footer, bool: 'LBXc[Blue2,Pink]')
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
        expect(ltx).to match(/\\textcolor{Tomato1}{\\bfseries{\\itshape{Std Dev}}/)
        tmp = File.open("#{__dir__}/../../tmp/example2.tex", 'w')
        result = false
        Dir.chdir(File.dirname(tmp.path)) do
          tmp << ltx
          tmp.flush
          result = system("#{ltxcmd} #{tmp.path} >/dev/null 2>&1")
          result &&= system("#{ltxcmd} #{tmp.path} >/dev/null 2>&1")
        end
        expect(result).to be true
      end
    end
  end
end
