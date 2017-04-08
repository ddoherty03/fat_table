require 'spec_helper'

module FatCore
  describe Formatter do
    before :all do
      aoa =
        [['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
         nil,
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
         [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']]
      @tab = Table.from_aoa(aoa)
    end

    describe 'parsing and validity' do
      it 'should raise error for invalid location' do
        fmt = Formatter.new(@tab)
        expect {
          fmt.format_for(:trout, string: 'BC')
        }.to raise_error(/unknown format location/)
      end

      it 'should raise error for invalid format string' do
        fmt = Formatter.new(@tab)
        expect {
          fmt.format_for(:body, string: 'OOIUOIO')
        }.to raise_error(/unrecognized string formatting instruction/)
      end

      it 'should raise error for inapposite format string' do
        fmt = Formatter.new(@tab)
        expect {
          fmt.format_for(:body, boolean: '7.4,')
        }.to raise_error(/unrecognized boolean formatting instruction/)
      end

      it 'should be able to set element formats' do
        fmt = Formatter.new(@tab)
                .format_for(:header, string: 'Uc[red]', ref: 'uc[blue.aquamarine]')
                .format_for(:gfooter, string: 'B')
                .format_for(:footer, date: 'Bd[%Y]')
                .format_for(:body, numeric: ',0.2', shares: '0.4', ref: 'B',
                            price: '$,',
                            bool: '  c[white.green, red.white]  b[  Yippers, Nah Sir]',
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
        @tab.headers.each do |h|
          expect(fmt.format_at[:header][h].true_color).to eq('none')
          expect(fmt.format_at[:header][h].false_color).to eq('none')
          expect(fmt.format_at[:header][h].true_text).to eq('T')
          expect(fmt.format_at[:header][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:header][h].nil_text).to eq('')
          expect(fmt.format_at[:header][h].pre_digits).to eq(-1)
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
        @tab.headers.each do |h|
          expect(fmt.format_at[:gfooter][h].bold).to eq(true)
        end
        # Gfooter all others, the default
        @tab.headers.each do |h|
          expect(fmt.format_at[:gfooter][h].true_color).to eq('none')
          expect(fmt.format_at[:gfooter][h].false_color).to eq('none')
          expect(fmt.format_at[:gfooter][h].color).to eq('none')
          expect(fmt.format_at[:gfooter][h].true_text).to eq('T')
          expect(fmt.format_at[:gfooter][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:gfooter][h].nil_text).to eq('')
          expect(fmt.format_at[:gfooter][h].pre_digits).to eq(-1)
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
        @tab.headers.each do |h|
          expect(fmt.format_at[:footer][h].true_color).to eq('none')
          expect(fmt.format_at[:footer][h].false_color).to eq('none')
          expect(fmt.format_at[:footer][h].color).to eq('none')
          expect(fmt.format_at[:footer][h].true_text).to eq('T')
          expect(fmt.format_at[:footer][h].false_text).to eq('F')
          expect(fmt.format_at[:header][h].date_fmt).to eq('%F')
          expect(fmt.format_at[:header][h].datetime_fmt).to eq('%F %H:%M:%S')
          expect(fmt.format_at[:footer][h].nil_text).to eq('')
          expect(fmt.format_at[:footer][h].pre_digits).to eq(-1)
          expect(fmt.format_at[:footer][h].post_digits).to eq(-1)
          expect(fmt.format_at[:footer][h].bold).to eq(h == :date)
          expect(fmt.format_at[:footer][h].italic).to eq(false)
          expect(fmt.format_at[:footer][h].alignment).to eq(:left)
          expect(fmt.format_at[:footer][h].commas).to eq(false)
          expect(fmt.format_at[:footer][h].currency).to eq(false)
          expect(fmt.format_at[:footer][h].nil_text).to eq('')
        end
        # .format_for(:body, numeric: ',0.2', shares: '0.4', ref: 'B',
        #             bool: '  c[green, red]  b[  Yippers, Nah Sir]',
        #             nil: 'n[  Nothing to see here   ]')
        # Body, numeric columns except :shares
        [:raw, :price].each do |h|
          expect(fmt.format_at[:body][h].commas).to eq(true)
          expect(fmt.format_at[:body][h].pre_digits).to eq(0)
          expect(fmt.format_at[:body][h].post_digits).to eq(2)
        end
        # Body, :shares
        expect(fmt.format_at[:body][:shares].commas).to eq(true)
        expect(fmt.format_at[:body][:shares].pre_digits).to eq(0)
        expect(fmt.format_at[:body][:shares].post_digits).to eq(4)
        # Body, :bool
        expect(fmt.format_at[:body][:bool].true_color).to eq('white')
        expect(fmt.format_at[:body][:bool].true_bgcolor).to eq('green')
        expect(fmt.format_at[:body][:bool].false_color).to eq('red')
        expect(fmt.format_at[:body][:bool].false_bgcolor).to eq('white')
        expect(fmt.format_at[:body][:bool].true_text).to eq('Yippers')
        expect(fmt.format_at[:body][:bool].false_text).to eq('Nah Sir')
        # Body, :ref
        expect(fmt.format_at[:body][:ref].bold).to eq(true)
        # Body, :price
        expect(fmt.format_at[:body][:price].currency).to eq(true)
        # Body all others, the default
        @tab.headers.each do |h|
          expect(fmt.format_at[:body][h].color).to eq('none')
          unless h == :bool
            expect(fmt.format_at[:body][h].true_color).to eq('none')
            expect(fmt.format_at[:body][h].false_color).to eq('none')
            expect(fmt.format_at[:body][h].true_text).to eq('T')
            expect(fmt.format_at[:body][h].false_text).to eq('F')
          end
          expect(fmt.format_at[:body][h].date_fmt).to eq('%F')
          if @tab.type(h) == 'Numeric'
            expect(fmt.format_at[:body][h].pre_digits).to eq(0)
            expect(fmt.format_at[:body][h].post_digits)
              .to eq(h == :shares ? 4 : 2)
            expect(fmt.format_at[:body][h].commas).to eq(true)
            expect(fmt.format_at[:body][h].bold).to eq(h == :ref)
            expect(fmt.format_at[:body][h].currency).to eq(h == :price)
          else
            expect(fmt.format_at[:body][h].italic).to eq(false)
            expect(fmt.format_at[:body][h].alignment).to eq(:left)
            expect(fmt.format_at[:body][h].currency).to eq(false)
            expect(fmt.format_at[:body][h].nil_text).to eq('Nothing to see here')
          end
        end
      end
    end

    describe 'cell formatting' do
      it 'should be able to format a string' do
        fmt = Formatter.new
        istruct = OpenStruct.new(Formatter.default_format)
        istruct.case = :upper
        expect(fmt.format_cell('hello world', istruct)).to eq('HELLO WORLD')
        istruct.case = :lower
        expect(fmt.format_cell('HELLO WORLD', istruct)).to eq('hello world')
        istruct.case = :title
        expect(fmt.format_cell('HELLO TO THE WORLD', istruct))
          .to eq('Hello to the World')
        expect(fmt.format_cell(nil, istruct))
          .to eq('')
      end

      it 'should be able to format a numeric' do
        fmt = Formatter.new
        istruct = OpenStruct.new(Formatter.default_format)
        expect(fmt.format_cell(78546.254, istruct)).to eq('78546.254')
        istruct.commas = true
        expect(fmt.format_cell(78546.254, istruct)).to eq('78,546.254')
        istruct.hms = true
        expect(fmt.format_cell(78546.254, istruct)).to eq('21:49:06.25')
        istruct.hms = false
        istruct.pre_digits = 8
        expect(fmt.format_cell(78546.254, istruct)).to eq('00078546')
        istruct.post_digits = 1
        expect(fmt.format_cell(78546.254, istruct)).to eq('00078546.3')
        istruct.commas = true
        expect(fmt.format_cell(78546.254, istruct)).to eq('00,078,546.3')
        istruct.commas = false
        istruct.pre_digits = -1
        istruct.post_digits = 2
        expect(fmt.format_cell(78546.254, istruct)).to eq('78546.25')
        istruct.currency = true
        istruct.post_digits = 5
        expect(fmt.format_cell(78546.254, istruct)).to eq('$78546.25400')
        istruct.commas = true
        expect(fmt.format_cell(78546.254, istruct)).to eq('$78,546.25400')
      end

      it 'should be able to format a boolean' do
        fmt = Formatter.new
        istruct = OpenStruct.new(Formatter.default_format)
        expect(fmt.format_cell(true, istruct)).to eq('T')
        expect(fmt.format_cell(false, istruct)).to eq('F')
        istruct.true_text = 'Yippers'
        istruct.false_text = 'Nappers'
        expect(fmt.format_cell(true, istruct)).to eq('Yippers')
        expect(fmt.format_cell(false, istruct)).to eq('Nappers')
      end

      it 'should be able to format a datetime' do
        fmt = Formatter.new
        istruct = OpenStruct.new(Formatter.default_format)
        val = DateTime.parse('2017-02-23 9pm')
        expect(fmt.format_cell(val, istruct)).to eq('2017-02-23 21:00:00')
        istruct.datetime_fmt = '%Y in %B at %l%P, which was on a %A'
        expect(fmt.format_cell(val, istruct))
          .to eq('2017 in February at  9pm, which was on a Thursday')
      end
    end

    describe 'footers' do
      before :each do
        aoa =
          [['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
           nil,
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
           [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']]
        @tab = Table.from_aoa(aoa).order_by(:date)
      end

      it 'should be able to add a total footer to the output' do
        fmt = Formatter.new(@tab) do |f|
          f.sum_footer(:raw, :shares, :price)
        end
        expect(fmt.footers['Total'][:raw]).to eq(:sum)
        expect(fmt.footers['Total'][:shares]).to eq(:sum)
        expect(fmt.footers['Total'][:price]).to eq(:sum)
        expect(fmt.footers['Total'][:info]).to be_nil
      end

      it 'should be able to add an average footer to the output' do
        fmt = Formatter.new(@tab) do |f|
          f.avg_footer(:raw, :shares, :price)
        end
        expect(fmt.footers['Average'][:raw]).to eq(:avg)
        expect(fmt.footers['Average'][:shares]).to eq(:avg)
        expect(fmt.footers['Average'][:price]).to eq(:avg)
        expect(fmt.footers['Average'][:info]).to be_nil
      end

      it 'should be able to add a minimum footer to the output' do
        fmt = Formatter.new(@tab) do |f|
          f.min_footer(:raw, :shares, :price)
        end
        expect(fmt.footers['Minimum'][:raw]).to eq(:min)
        expect(fmt.footers['Minimum'][:shares]).to eq(:min)
        expect(fmt.footers['Minimum'][:price]).to eq(:min)
        expect(fmt.footers['Minimum'][:info]).to be_nil
      end

      it 'should be able to add a maximum footer to the output' do
        fmt = Formatter.new(@tab) do |f|
          f.max_footer(:raw, :shares, :price)
        end
        expect(fmt.footers['Maximum'][:raw]).to eq(:max)
        expect(fmt.footers['Maximum'][:shares]).to eq(:max)
        expect(fmt.footers['Maximum'][:price]).to eq(:max)
        expect(fmt.footers['Maximum'][:info]).to be_nil
      end
    end

    describe 'table output' do
      before :each do
        aoa =
          [['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
           nil,
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
           [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T']]
        @tab = Table.from_aoa(aoa).order_by(:date)
      end

      it 'should be able to output a table with default formatting instructions' do
        str = Formatter.new(@tab).output
        expect(str.length).to be > 10
      end

      it 'should be able to set format and output by method calls' do
        fmt = Formatter.new(@tab)
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

      it 'should be able to set format and output in a block' do
        fmt = Formatter.new(@tab) do |f|
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
