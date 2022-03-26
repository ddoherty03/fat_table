module FatTable
  RSpec.describe Formatter do
    let(:tab) {
      aoa = [
        %w[Ref Date Code Raw Shares Price Info Bool],
        [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
        [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1', 'T'],
        [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ZMEAC', 'F'],
        [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ZMEAC', 'T'],
        [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ZMEAC', 'T'],
        [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ZMEAC', 'T'],
        [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ZMEAC', 'F'],
        [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ZMEAC', 'T'],
        [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ZMEAC', 'T'],
        [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ZMEAC', 'F'],
        [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ZMEAC', 'T'],
        [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']
      ]
      Table.from_aoa(aoa)
    }

    describe 'empty table' do
      it 'produces just headers on an empty table with headers' do
        empty_tab = Table.new(:a, :b, :c, :d)
        out = empty_tab.to_text
        expect(out).to match(/\| A \| B \|/)
        expect(out.split("\n").size).to eq(3)
      end

      it 'produces headers and blank footer on an empty table with headers and footers' do
        empty_tab = Table.new(:a, :b, :c, :d)
        out = empty_tab.to_text do |f|
          f.sum_footer(:d)
          f.sum_gfooter(:d)
        end
        expect(out).to match(/\| A *\| B \|/)
        expect(out).to match(/\| Total \|/)
        expect(out.split("\n").size).to eq(5)
      end

      it 'produces an empty string on an empty table with no headers' do
        empty_tab = Table.new
        out = empty_tab.to_text
        expect(out).to eq('')
      end
    end

    describe 'parsing and validity' do
      describe 'invalid format strings' do
        it 'raises an error for invalid location' do
          fmt = described_class.new(tab)
          expect {
            fmt.format_for(:trout, string: 'BC')
          }.to raise_error(/unknown format location/)
        end

        it 'raises an error for invalid format string' do
          fmt = described_class.new(tab)
          expect {
            fmt.format_for(:body, string: 'OOIUOIO')
          }.to raise_error(/unrecognized string formatting instruction/)
        end

        it 'raises an error for inapposite format string' do
          fmt = described_class.new(tab)
          expect {
            fmt.format_for(:body, boolean: '7.4,')
          }.to raise_error(/unrecognized boolean formatting instruction/)
        end
      end

      describe 'parsing format strings', :aggregate_failures do
        describe '#parse_numeric_format' do
          let(:fmt) { described_class.new(tab) }

          it 'properly parses a dollar and comma' do
            fh = fmt.send(:parse_numeric_fmt, '$,R').first
            expect(fh[:commas]).to be_truthy
            expect(fh[:currency]).to be_truthy
          end
        end
      end

      describe 'formmater for nil entries' do
        it 'should parse nil directive' do
          fmt = described_class.new(tab)
          fmt.format_for(:body, nil: 'Rn[No Data]')
          expect(fmt.format_at[:body][:info].nil_text).to eq('No Data')
          expect(fmt.format_at[:body][:info].alignment).to eq(:right)
          fmt = described_class.new(tab)
          fmt.format_for(:body, nilclass: 'Rn[No Data]')
          expect(fmt.format_at[:body][:info].nil_text).to eq('No Data')
          expect(fmt.format_at[:body][:info].alignment).to eq(:right)
        end

        it 'should parse nil for a string type' do
          fmt = described_class.new(tab)
          fmt.format_for(:body, string: 'Rn[No Data]')
          expect(fmt.format_at[:body][:info].nil_text).to eq('No Data')
          fmt = described_class.new(tab)
          fmt.format_for(:body, info: 'Rn[No Data]')
          expect(fmt.format_at[:body][:info].nil_text).to eq('No Data')
        end

        it 'should parse nil for a numeric type' do
          fmt = described_class.new(tab)
          fmt.format_for(:body, numeric: '3.2n[No Data]')
          expect(fmt.format_at[:body][:shares].nil_text).to eq('No Data')
          fmt = described_class.new(tab)
          fmt.format_for(:body, shares: '3.2n[No Data]')
          expect(fmt.format_at[:body][:shares].nil_text).to eq('No Data')
        end

        it 'should parse nil for a boolean type' do
          fmt = described_class.new(tab)
          fmt.format_for(:body, boolean: 'Yn[No Data]')
          expect(fmt.format_at[:body][:bool].nil_text).to eq('No Data')
          fmt = described_class.new(tab)
          fmt.format_for(:body, bool: 'Yn[No Data]')
          expect(fmt.format_at[:body][:bool].nil_text).to eq('No Data')
        end

        it 'should parse nil for a datetime type' do
          fmt = described_class.new(tab)
          fmt.format_for(:body, datetime: 'd[%Y %m]n[No Data]')
          expect(fmt.format_at[:body][:date].nil_text).to eq('No Data')
          fmt = described_class.new(tab)
          fmt.format_for(:body, date: 'd[%Y %m]n[No Data]')
          expect(fmt.format_at[:body][:date].nil_text).to eq('No Data')
        end
      end

      describe 'font style formmating' do
        it 'should parse bold or not bold' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0B')
          expect(fmt.format_at[:body][:shares].bold).to eq(true)
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0~ B')
          expect(fmt.format_at[:body][:shares].bold).to eq(false)
        end

        it 'should parse italic or not italic' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0I')
          expect(fmt.format_at[:body][:shares].italic).to eq(true)
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0~ I')
          expect(fmt.format_at[:body][:shares].italic).to eq(false)
        end

        it 'should parse underline or not underline' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0_')
          expect(fmt.format_at[:body][:shares].underline).to eq(true)
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0~ _')
          expect(fmt.format_at[:body][:shares].underline).to eq(false)
        end

        it 'should parse blink or not blink' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0*')
          expect(fmt.format_at[:body][:shares].blink).to eq(true)
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0~ *')
          expect(fmt.format_at[:body][:shares].blink).to eq(false)
        end
      end

      describe 'grouping commas for numerics' do
        it 'parses comma described_class' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0,')
          expect(fmt.format_at[:body][:shares].commas).to eq(true)
        end

        it 'parses negated comma described_class' do
          fmt = described_class.new(tab)
                  .format_for(:body, numeric: '4.0,', shares: '4.0~,')
          expect(fmt.format_at[:body][:shares].commas).to eq(false)
        end
      end

      it 'should parse currency or not currency' do
        fmt = described_class.new(tab)
                .format_for(:body, numeric: '4.0$')
        expect(fmt.format_at[:body][:shares].currency).to eq(true)
        fmt = described_class.new(tab)
                .format_for(:body, numeric: '4.0~ $')
        expect(fmt.format_at[:body][:shares].currency).to eq(false)
      end

      it 'should parse hms or not hms' do
        fmt = described_class.new(tab)
                .format_for(:body, numeric: '4.0H')
        expect(fmt.format_at[:body][:shares].hms).to eq(true)
        fmt = described_class.new(tab)
                .format_for(:body, numeric: '4.0~ H')
        expect(fmt.format_at[:body][:shares].hms).to eq(false)
      end

      it 'should give priority to column over type formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, numeric: '4.0', shares: '0.4')
        expect(fmt.format_at[:body][:shares].pre_digits).to eq(0)
        expect(fmt.format_at[:body][:shares].post_digits).to eq(4)
      end

      it 'should give priority to column over string formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, string: 'c[red]', shares: 'c[blue]')
        expect(fmt.format_at[:body][:shares].color).to eq('blue')
      end

      it 'should give priority to column over nil formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, nil: 'n[Blank]', shares: 'n[Nada]')
        expect(fmt.format_at[:body][:shares].nil_text).to eq('Nada')
      end

      it 'should give priority to type over string formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, string: 'c[red]', numeric: 'c[blue]')
        expect(fmt.format_at[:body][:shares].color).to eq('blue')
      end

      it 'should give priority to type over nil formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, nil: 'n[Blank]', numeric: 'n[Nada]')
        expect(fmt.format_at[:body][:shares].nil_text).to eq('Nada')
      end

      it 'should give priority to nil over string formatting' do
        fmt = described_class.new(tab)
                .format_for(:body, nil: 'n[Blank]', string: 'n[Nada]')
        expect(fmt.format_at[:body][:shares].nil_text).to eq('Blank')
      end

      it 'should give priority to bfirst over body formatting' do
        fmt = described_class.new(tab)
                .format_for(:bfirst, ref: '3.1')
                .format_for(:body, ref: '4.0')
        expect(fmt.format_at[:bfirst][:ref][:_location]).to eq(:bfirst)
        expect(fmt.format_at[:bfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:bfirst][:ref].pre_digits).to eq(3)
        expect(fmt.format_at[:bfirst][:ref].post_digits).to eq(1)
      end

      it 'bfirst should inherit body formatting with possible override' do
        fmt = described_class.new(tab)
                .format_for(:bfirst, ref: 'c[red]')
                .format_for(:body, ref: '4.0')
        expect(fmt.format_at[:bfirst][:ref][:_location]).to eq(:bfirst)
        expect(fmt.format_at[:bfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:bfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:bfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:bfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:body][:ref].color).to eq('none')
        # Regardless of the order
        fmt = described_class.new(tab)
                .format_for(:body, ref: '4.0')
                .format_for(:bfirst, ref: 'c[red]')
        expect(fmt.format_at[:bfirst][:ref][:_location]).to eq(:bfirst)
        expect(fmt.format_at[:bfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:bfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:bfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:bfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:body][:ref].color).to eq('none')
      end

      it 'gfirst should inherit body formatting with possible override' do
        fmt = described_class.new(tab)
                .format_for(:gfirst, ref: 'c[red]')
                .format_for(:body, ref: '4.0')
        expect(fmt.format_at[:gfirst][:ref][:_location]).to eq(:gfirst)
        expect(fmt.format_at[:gfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:gfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:gfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:gfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:body][:ref].color).to eq('none')
        # Regardless of the order
        fmt = described_class.new(tab)
                .format_for(:body, ref: '4.0')
                .format_for(:gfirst, ref: 'c[red]')
        expect(fmt.format_at[:gfirst][:ref][:_location]).to eq(:gfirst)
        expect(fmt.format_at[:gfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:gfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:gfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:gfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:body][:ref].color).to eq('none')
      end

      it 'bfirst should inherit gfirst formatting with possible override' do
        fmt = described_class.new(tab)
                .format_for(:bfirst, ref: 'c[red]')
                .format_for(:gfirst, ref: '4.0')
        expect(fmt.format_at[:bfirst][:ref][:_location]).to eq(:bfirst)
        expect(fmt.format_at[:bfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:bfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:bfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:bfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:gfirst][:ref].color).to eq('none')
        # Regardless of the order
        fmt = described_class.new(tab)
                .format_for(:gfirst, ref: '4.0')
                .format_for(:bfirst, ref: 'c[red]')
        expect(fmt.format_at[:bfirst][:ref][:_location]).to eq(:bfirst)
        expect(fmt.format_at[:bfirst][:ref][:_h]).to eq(:ref)
        expect(fmt.format_at[:bfirst][:ref].pre_digits).to eq(4)
        expect(fmt.format_at[:bfirst][:ref].post_digits).to eq(0)
        expect(fmt.format_at[:bfirst][:ref].color).to eq('red')
        expect(fmt.format_at[:gfirst][:ref].color).to eq('none')
      end

      it 'should be able to set element formats' do
        fmt = described_class.new(tab)
                .format_for(:header, string: 'Uc[red]',
                            ref: 'uc[blue.aquamarine]')
                .format_for(:gfooter, string: 'B')
                .format_for(:footer, datetime: 'Bd[%Y]')
                .format_for(:body, numeric: ',0.2', shares: '0.4', ref: 'B',
                            price: '$,',
                            bool: '  c[white.green, red.white] b[  Yippers, Nah Sir]',
                            datetime: 'd[%Y]D[%v]',
                            nil: 'n[  Nothing to see here   ]')
        # Header color
        expect(fmt.format_at[:header][:ref].color).to eq('blue')
        expect(fmt.format_at[:header][:ref].bgcolor).to eq('aquamarine')
        expect(fmt.format_at[:header][:date].color).to eq('red')
        expect(fmt.format_at[:header][:date].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:code].color).to eq('red')
        expect(fmt.format_at[:header][:code].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:raw].color).to eq('red')
        expect(fmt.format_at[:header][:raw].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:shares].color).to eq('red')
        expect(fmt.format_at[:header][:shares].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:price].color).to eq('red')
        expect(fmt.format_at[:header][:price].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:info].color).to eq('red')
        expect(fmt.format_at[:header][:info].bgcolor).to eq('none')
        expect(fmt.format_at[:header][:bool].color).to eq('red')
        expect(fmt.format_at[:header][:bool].bgcolor).to eq('none')
        # Header case
        expect(fmt.format_at[:header][:ref].case).to eq(:lower)
        expect(fmt.format_at[:header][:date].case).to eq(:upper)
        expect(fmt.format_at[:header][:code].case).to eq(:upper)
        expect(fmt.format_at[:header][:raw].case).to eq(:upper)
        expect(fmt.format_at[:header][:shares].case).to eq(:upper)
        expect(fmt.format_at[:header][:price].case).to eq(:upper)
        expect(fmt.format_at[:header][:info].case).to eq(:upper)
        expect(fmt.format_at[:header][:bool].case).to eq(:upper)
        # Header all others, the default
        tab.headers.each do |h|
          expect(fmt.format_at[:header][h].true_color).to eq('none')
          expect(fmt.format_at[:header][h].false_color).to eq('none')
          expect(fmt.format_at[:header][h].true_text).to eq('T')
          expect(fmt.format_at[:header][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:header][h].nil_text).to eq('')
          expect(fmt.format_at[:header][h].pre_digits).to eq(0)
          expect(fmt.format_at[:header][h].post_digits).to eq(-1)
          expect(fmt.format_at[:header][h].bold).to eq(false)
          expect(fmt.format_at[:header][h].italic).to eq(false)
          expect(fmt.format_at[:header][h].alignment).to eq(:left)
          expect(fmt.format_at[:header][h].commas).to eq(false)
          expect(fmt.format_at[:header][h].currency).to eq(false)
          expect(fmt.format_at[:header][h].nil_text).to eq('')
          expect(fmt.format_at[:header][h].underline).to eq(false)
          expect(fmt.format_at[:header][h].blink).to eq(false)
        end
        # Gfooter bold
        tab.headers.each do |h|
          expect(fmt.format_at[:gfooter][h].bold).to eq(true)
        end
        # Gfooter all others, the default
        tab.headers.each do |h|
          expect(fmt.format_at[:gfooter][h].true_color).to eq('none')
          expect(fmt.format_at[:gfooter][h].false_color).to eq('none')
          expect(fmt.format_at[:gfooter][h].color).to eq('none')
          expect(fmt.format_at[:gfooter][h].true_text).to eq('T')
          expect(fmt.format_at[:gfooter][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:gfooter][h].nil_text).to eq('')
          expect(fmt.format_at[:gfooter][h].pre_digits).to eq(0)
          expect(fmt.format_at[:gfooter][h].post_digits).to eq(-1)
          expect(fmt.format_at[:gfooter][h].italic).to eq(false)
          expect(fmt.format_at[:gfooter][h].alignment).to eq(:left)
          expect(fmt.format_at[:gfooter][h].commas).to eq(false)
          expect(fmt.format_at[:gfooter][h].currency).to eq(false)
          expect(fmt.format_at[:gfooter][h].nil_text).to eq('')
        end
        # Footer date_fmt for :date
        expect(fmt.format_at[:footer][:date].date_fmt).to eq('%Y')
        expect(fmt.format_at[:footer][:date].bold).to eq(true)
        # Footer all others, the default
        tab.headers.each do |h|
          expect(fmt.format_at[:footer][h].true_color).to eq('none')
          expect(fmt.format_at[:footer][h].false_color).to eq('none')
          expect(fmt.format_at[:footer][h].color).to eq('none')
          expect(fmt.format_at[:footer][h].true_text).to eq('T')
          expect(fmt.format_at[:footer][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:footer][h].nil_text).to eq('')
          expect(fmt.format_at[:footer][h].pre_digits).to eq(0)
          expect(fmt.format_at[:footer][h].post_digits).to eq(-1)
          expect(fmt.format_at[:footer][h].bold).to eq(h == :date)
          expect(fmt.format_at[:footer][h].italic).to eq(false)
          expect(fmt.format_at[:footer][h].alignment).to eq(:left)
          expect(fmt.format_at[:footer][h].commas).to eq(false)
          expect(fmt.format_at[:footer][h].currency).to eq(false)
          expect(fmt.format_at[:footer][h].nil_text).to eq('')
        end
        # Body, :raw (inherit numeric)
        expect(fmt.format_at[:body][:raw].commas).to eq(true)
        expect(fmt.format_at[:body][:raw].pre_digits).to eq(0)
        expect(fmt.format_at[:body][:raw].post_digits).to eq(2)
        # Body, :price
        expect(fmt.format_at[:body][:price].commas).to eq(true)
        expect(fmt.format_at[:body][:price].pre_digits).to eq(0)
        expect(fmt.format_at[:body][:price].post_digits).to eq(-1)
        # Body, :shares
        expect(fmt.format_at[:body][:shares].commas).to eq(false)
        expect(fmt.format_at[:body][:shares].pre_digits).to eq(0)
        expect(fmt.format_at[:body][:shares].post_digits).to eq(4)
        # Body, :bool
        expect(fmt.format_at[:body][:bool].true_color).to eq('white')
        expect(fmt.format_at[:body][:bool].true_bgcolor).to eq('green')
        expect(fmt.format_at[:body][:bool].false_color).to eq('red')
        expect(fmt.format_at[:body][:bool].false_bgcolor).to eq('white')
        expect(fmt.format_at[:body][:bool].true_text).to eq('Yippers')
        expect(fmt.format_at[:body][:bool].false_text).to eq('Nah Sir')
        # Body, :datetime
        expect(fmt.format_at[:body][:date].date_fmt).to eq('%Y')
        expect(fmt.format_at[:body][:date].datetime_fmt).to eq('%v')
        # Body, :ref
        expect(fmt.format_at[:body][:ref].bold).to eq(true)
        # Body, :price
        expect(fmt.format_at[:body][:price].currency).to eq(true)
        # Body all others, the default
        %i[date code info].each do |h|
          expect(fmt.format_at[:body][h].color).to eq('none')
          expect(fmt.format_at[:body][h].true_color).to eq('none')
          expect(fmt.format_at[:body][h].false_color).to eq('none')
          expect(fmt.format_at[:body][h].true_text).to eq('T')
          expect(fmt.format_at[:body][h].false_text).to eq('F')
          expect(fmt.format_at[:body][h].italic).to eq(false)
          expect(fmt.format_at[:body][h].alignment).to eq(:left)
          expect(fmt.format_at[:body][h].currency).to eq(false)
          expect(fmt.format_at[:body][h].nil_text).to eq('Nothing to see here')
        end
      end
    end

    describe 'cell formatting' do
      let(:fmt) { described_class.new }

      before do
        @istruct = OpenStruct.new(described_class.default_format)
      end

      # let(:istruct) { OpenStruct.new(described_class.default_format) }

      describe 'string formatting' do
        it 'properly uppercases a string' do
          @istruct = OpenStruct.new(described_class.default_format)
          @istruct.case = :upper
          expect(fmt.format_cell('hello world', @istruct)).to eq('HELLO WORLD')
        end

        it 'properly downcases a string' do
          @istruct.case = :lower
          expect(fmt.format_cell('HELLO WORLD', @istruct)).to eq('hello world')
        end

        it 'properly title cases a string' do
          @istruct.case = :title
          expect(fmt.format_cell('HELLO TO THE WORLD', @istruct))
            .to eq('Hello to the World')
        end

        it 'properly formats a nil as an empty string' do
          expect(fmt.format_cell(nil, @istruct)).to eq('')
        end
      end

      describe 'numeric formatting' do
        it 'adds grouping commas' do
          @istruct.commas = true
          expect(fmt.format_cell(78546.254, @istruct)).to eq('78,546.254')
        end

        it 'converts to HMS' do
          @istruct.hms = true
          expect(fmt.format_cell(78546.254, @istruct)).to eq('21:49:06.25')
        end

        it 'handles pre-digits with zero padding' do
          @istruct.pre_digits = 8
          expect(fmt.format_cell(78546.254, @istruct)).to eq('00078546')
        end

        it 'rounds to the the number of post-digits' do
          @istruct.pre_digits = 8
          @istruct.post_digits = 1
          expect(fmt.format_cell(78546.254, @istruct)).to eq('00078546.3')
          expect(fmt.format_cell(78546.234, @istruct)).to eq('00078546.2')
        end

        it 'adds commas and pre-digit padding' do
          @istruct.commas = true
          @istruct.pre_digits = 8
          @istruct.post_digits = 1
          expect(fmt.format_cell(78546.254, @istruct)).to eq('00,078,546.3')
        end

        it 'handles negative pre-digits' do
          @istruct.commas = false
          @istruct.pre_digits = -1
          @istruct.post_digits = 2
          expect(fmt.format_cell(78546.254, @istruct)).to eq('78546.25')
        end

        it 'handles currency with post-digits' do
          @istruct.currency = true
          @istruct.post_digits = 5
          expect(fmt.format_cell(78546.254, @istruct)).to eq('$78546.25400')
        end

        it 'formats currency with commas' do
          @istruct.currency = true
          @istruct.commas = true
          expect(fmt.format_cell(78546.254, @istruct)).to eq('$78,546.25')
        end
      end

      describe 'boolean formatting' do
        it 'properly formats a boolean' do
          fmt = described_class.new
          @istruct = OpenStruct.new(described_class.default_format)
          expect(fmt.format_cell(true, @istruct)).to eq('T')
          expect(fmt.format_cell(false, @istruct)).to eq('F')
          @istruct.true_text = 'Yippers'
          @istruct.false_text = 'Nappers'
          expect(fmt.format_cell(true, @istruct)).to eq('Yippers')
          expect(fmt.format_cell(false, @istruct)).to eq('Nappers')
        end
      end

      describe 'datetime formatting' do
        it 'properly formats a datetime with sub-day components' do
          fmt = described_class.new
          @istruct = OpenStruct.new(described_class.default_format)
          val = DateTime.parse('2017-02-23 9pm')
          expect(fmt.format_cell(val, @istruct)).to eq('2017-02-23 21:00:00')
          @istruct.datetime_fmt = '%Y in %B at %l%P, which was on a %A'
          expect(fmt.format_cell(val, @istruct))
            .to eq('2017 in February at  9pm, which was on a Thursday')
        end

        it 'properly formats a datetime without sub-day components' do
          fmt = described_class.new
          @istruct = OpenStruct.new(described_class.default_format)
          val = DateTime.parse('2017-02-23')
          expect(fmt.format_cell(val, @istruct)).to eq('2017-02-23')
          @istruct.date_fmt = '%Y in %B at %l%P, which was on a %A'
          expect(fmt.format_cell(val, @istruct))
            .to eq('2017 in February at 12am, which was on a Thursday')
        end
      end
    end

    describe 'footers' do
      let(:tab) {
        aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
          [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500,
           'ZMPEF1', 'T'],
          [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ZMEAC', 'F'],
          [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ZMEAC', 'T'],
          [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ZMEAC', 'T'],
          [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ZMEAC', 'T'],
          [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ZMEAC', 'F'],
          [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ZMEAC', 'T'],
          [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ZMEAC', 'T'],
          [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ZMEAC', 'F'],
          [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ZMEAC', 'T'],
          [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']
        ]
        FatTable::Table.from_aoa(aoa).order_by(:date)
      }

      it 'adds a total footer to the output' do
        fmt = described_class.new(tab) do |f|
          f.sum_footer(:raw, :shares, :price)
        end
        expect(fmt.footers['Total'].to_h[:ref]).to eq('Total')
        expect(fmt.footers['Total'].to_h[:raw].class).to eq(BigDecimal)
        expect(fmt.footers['Total'].to_h[:shares].class).to eq(BigDecimal)
        expect(fmt.footers['Total'].to_h[:price].class).to eq(BigDecimal)
        expect(fmt.footers['Total'].to_h[:info]).to be_nil
      end

      it 'adds an average footer to the output' do
        fmt = described_class.new(tab) do |f|
          f.avg_footer(:raw, :shares, :price)
        end
        foot_hash = fmt.footers['Average'].to_h
        expect(foot_hash[:ref]).to eq('Average')
        expect(foot_hash[:raw].class).to be(BigDecimal)
        expect(foot_hash[:shares].class).to be(BigDecimal)
        expect(foot_hash[:price].class).to be(BigDecimal)
        expect(foot_hash[:info]).to be_nil
      end

      it 'adds a minimum footer to the output' do
        fmt = described_class.new(tab) do |f|
          f.min_footer(:raw, :shares, :price)
        end
        foot_hash = fmt.footers['Minimum'].to_h
        expect(foot_hash[:raw].class).to eq(BigDecimal)
        expect(foot_hash[:shares].class).to eq(BigDecimal)
        expect(foot_hash[:price].class).to eq(BigDecimal)
        expect(foot_hash[:info]).to be_nil
      end

      it 'adds a maximum footer to the output' do
        fmt = described_class.new(tab) do |f|
          f.max_footer(:raw, :shares, :price)
        end
        foot_hash = fmt.footers['Maximum'].to_h
        expect(foot_hash[:raw].class).to eq(BigDecimal)
        expect(foot_hash[:shares].class).to eq(BigDecimal)
        expect(foot_hash[:price].class).to eq(BigDecimal)
        expect(foot_hash[:info]).to be_nil
      end

      describe 'table output' do
        let(:tab) {
          aoa = [
            %w[Ref Date Code Raw Shares Price Info Bool],
            [1  , '2013-05-02' , 'P' , 795_546.20 , 795_546.2 , 1.1850  , 'ZMPEF1' , 'T'] ,
            [2  , '2013-05-02' , 'P' , 118_186.40 , 118_186.4 , 11.8500 , 'ZMPEF1' , 'T'] ,
            [7  , '2013-05-20' , 'S' , 12_000.00  , 5046.00   , 28.2804 , 'ZMEAC'  , 'F'] ,
            [8  , '2013-05-20' , 'S' , 85_000.00  , 35_742.50 , 28.3224 , 'ZMEAC'  , 'T'] ,
            [9  , '2013-05-20' , 'S' , 33_302.00  , 14_003.49 , 28.6383 , 'ZMEAC'  , 'T'] ,
            [10 , '2013-05-23' , 'S' , 8000.00    , 3364.00   , 27.1083 , 'ZMEAC'  , 'T'] ,
            [11 , '2013-05-23' , 'S' , 23_054.00  , 9694.21   , 26.8015 , 'ZMEAC'  , 'F'] ,
            [12 , '2013-05-23' , 'S' , 39_906.00  , 16_780.47 , 25.1749 , 'ZMEAC'  , 'T'] ,
            [13 , '2013-05-29' , 'S' , 13_459.00  , 5659.51   , 24.7464 , 'ZMEAC'  , 'T'] ,
            [14 , '2013-05-29' , 'S' , 15_700.00  , 6601.85   , 24.7790 , 'ZMEAC'  , 'F'] ,
            [15 , '2013-05-29' , 'S' , 15_900.00  , 6685.95   , 24.5802 , 'ZMEAC'  , 'T'] ,
            [16 , '2013-05-30' , 'S' , 6_679.00   , 2808.52   , 25.0471 , 'ZMEAC'  , 'T']
          ]
          FatTable::Table.from_aoa(aoa).order_by(:date)
        }

        it 'outputs a table with default formatting' do
          str = described_class.new(tab).output
          expect(str.length).to be > 10
        end

        it 'prioritizes header formatting over type formatting' do
          txt = tab.to_text do |f|
            f.format(numeric: 'R0.2,', price: 'R0.4', ref: 'C4.0')
          end
          # The :ref, :share, :raw_shares, and :price columns are all numeric,
          # but the :price and :ref format directives override the :numeric
          # directive while the :raw_shares and :shares columns obey the
          # :numeric directive.
          line = "| 0001 | 2013-05-02 | P    | 795,546.20 | 795,546.20 |  1.1850 | ZMPEF1 | T    |"
          expect(txt).to match(Regexp.quote(line))

          # Order of instructions should not matter
          txt = tab.to_text do |f|
            f.format(ref: 'C4.0', numeric: 'R0.2,', price: 'R0.4')
          end
          expect(txt).to match(Regexp.quote(line))

          # Order of instructions should not matter
          txt = tab.to_text do |f|
            f.format(ref: 'C4.0', price: 'R0.4', numeric: 'R0.2,')
          end
          expect(txt).to match(Regexp.quote(line))
        end

        it 'sets format and output by footer and gfooter method calls' do
          fmt = described_class.new(tab)
          fmt.format(ref: '5.0', code: 'C', raw: ',0.0R', shares: ',0.0R',
                     price: '0.3', bool: 'Y')
          fmt.format_for(:header, string: 'CB')
          fmt.sum_gfooter(:price, :raw, :shares)
          fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
          fmt.sum_footer(:price, :raw, :shares)
          fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
          fmt.footer('Any?', bool: :any?)
          str = fmt.output
          expect(str.length).to be > 10
          expect(str).to match(/^Ref\|.*\|Bool$/)
          expect(str).to match(/^00001\|2013-05-02\|P\|795,546\|795,546\|1.185\|ZMPEF1\|Y$/)
          expect(str).to match(/^Group Total\|\|\|130,302\|54,792\|85.241\|\|$/)
          expect(str).to match(/^Total|||1,166,733|1,020,119|276.514||$/)
        end

        it 'allows footer aggregates to be lambdas' do
          fmt = described_class.new(tab)
          fmt.format(ref: '5.0', code: 'C', raw: ',0.0R', shares: ',0.0R',
                     price: '0.3', bool: 'Y')
          fmt.format_for(:header, string: 'CB')
          tgfoot = fmt.gfoot(label: 'Group Total', price: :sum, raw: :sum, shares: :sum, bool: 'Static')
          sqft = fmt.gfoot(label: 'Sqrt Group Total',
                           price: ->(k) { tgfoot.price(k).sqrt(12) },
                           raw: ->(k) { tgfoot.raw(k).sqrt(12) },
                           shares: ->(k) { tgfoot.shares(k).sqrt(12) },
                           bool: 'Static')
          tfoot = fmt.foot(label: 'Total', label_col: :date, price: :sum, raw: :sum, shares: :sum)
          fmt.foot(label: 'Sqrt Total', label_col: :date, price: -> { tfoot.price.sqrt(12) },
                   shares: -> { tfoot.shares.sqrt(12) },
                   raw: -> { tfoot.raw.sqrt(12) })
          str = fmt.output
          expect(str.length).to be > 10
          expect(str).to include("Group Total|||913,733|913,733|13.035||Static")
          expect(str).to include("Sqrt Group Total|||956|956|3.610||Static")
          expect(str).to include("Group Total|||130,302|54,792|85.241||Static")
          expect(str).to include("Sqrt Group Total|||361|234|9.233||Static")
          expect(str).to include("Group Total|||70,960|29,839|79.085||Static")
          expect(str).to include("Sqrt Group Total|||266|173|8.893||Static")
          expect(str).to include("Group Total|||45,059|18,947|74.106||Static")
          expect(str).to include("Sqrt Group Total|||212|138|8.608||Static")
          expect(str).to include("Group Total|||6,679|2,809|25.047||Static")
          expect(str).to include("Sqrt Group Total|||82|53|5.005||Static")
          expect(str).to include("|Total||1,166,733|1,020,119|276.514||")
          expect(str).to include("|Sqrt Total||1,080|1,010|16.629||")
        end

        it 'sets format and output in a block' do
          fmt = described_class.new(tab) do |f|
            f.format(ref: '5.0', code: 'C', raw: ',0.0R', shares: ',0.0R',
                     price: '0.3', bool: 'Y')
            f.format_for(:header, string: 'CB')
            f.sum_gfooter(:price, :raw, :shares)
            f.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
            f.sum_footer(:price, :raw, :shares)
            f.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
            f.footer('Any?', bool: :any?)
          end
          str = fmt.output
          expect(str.length).to be > 10
          expect(str).to match(/^Ref\|.*\|Bool$/)
          expect(str).to match(/^00001\|2013-05-02\|P\|795,546\|795,546\|1.185\|ZMPEF1\|Y$/)
          expect(str).to match(/^Group Total\|\|\|130,302\|54,792\|85.241\|\|$/)
          expect(str).to match(/^Total|||1,166,733|1,020,119|276.514||$/)
        end
      end
    end
  end
end
