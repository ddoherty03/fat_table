module FatTable
  RSpec.describe TermFormatter do
    describe 'table output' do
      before :all do
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
      end

      before :each do
        @aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          [1,  '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850,  'ZMPEF1',          'T'],
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
        @tab = Table.from_aoa(@aoa).order_by(:date)
      end

      it 'should raise an error for an invalid color' do
        expect {
          TermFormatter.new(@tab) do |f|
            f.format_for(:body, date: 'c[Yeller]')
          end
        }.to raise_error(/invalid color 'Yeller'/)
      end

      it 'should output unicode with default formatting' do
        trm = TermFormatter.new(@tab).output
        expect(trm.class).to eq(String)
      end

      it 'should be able to set format and output unicode with block' do
        fmt = TermFormatter.new(@tab)
        fmt.format(ref: '5.0', code: 'C', raw: ',0.0', shares: ',0.0',
                   price: '0.3R', bool: 'Y', numeric: 'R')
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        trm = fmt.output
        expect(trm).to match(/^#{UPPER_LEFT}[#{DOUBLE_RULE}#{UPPER_TEE}]+#{UPPER_RIGHT}$/)
        expect(trm).to match(/^#{LEFT_TEE}[#{HORIZONTAL_RULE}#{SINGLE_CROSS}]+#{RIGHT_TEE}$/)
        expect(trm).to match(/^#{LOWER_LEFT}[#{DOUBLE_RULE}#{LOWER_TEE}]+#{LOWER_RIGHT}$/)
        expect(trm.size).to be > 1000
        expect(trm).to match(/\bRef\b/)
        expect(trm).to match(/\bBool\b/)
        expect(trm).to match(/\b2013-05-02\b/)
        expect(trm).to match(/\D795,546\D/)
        expect(trm).to match(/\D1,031,919\D/)
        expect(trm).to match(/\D1.185\D/)
        expect(trm).to match(/\D24.885\D/)
        expect(trm).to match(/\D00001\D/)
        expect(trm).to match(/\bY\b/)
        expect(trm).to match(/\bP\b/)
        expect(trm).to match(/\bZMPEF1\b/)
        expect(trm).to match(/\bGroup Total\b/)
        expect(trm).to match(/\bGrp Std Dev\b/)
      end

      it 'should output non-unicode with default formatting' do
        trm = TermFormatter.new(@tab, unicode: false).output
        expect(trm.class).to eq(String)
      end

      it 'should be able to set format and output without unicode' do
        fmt = TermFormatter.new(@tab, unicode: false)
        fmt.format(ref: '5.0', code: 'C', raw: ',0.0', shares: ',0.0',
                   price: '0.3R', bool: 'Y', numeric: 'R')
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        trm = fmt.output
        expect(trm).to match(/^\+[=+]+\+$/)
        expect(trm).to match(/^\+[-+]+\+$/)
        expect(trm).to match(/^\+[=+]+\+$/)
        expect(trm.size).to be > 1000
        expect(trm).to match(/\bRef\b/)
        expect(trm).to match(/\bBool\b/)
        expect(trm).to match(/\b2013-05-02\b/)
        expect(trm).to match(/\D795,546\D/)
        expect(trm).to match(/\D1,031,919\D/)
        expect(trm).to match(/\D1.185\D/)
        expect(trm).to match(/\D24.885\D/)
        expect(trm).to match(/\D00001\D/)
        expect(trm).to match(/\bY\b/)
        expect(trm).to match(/\bP\b/)
        expect(trm).to match(/\bZMPEF1\b/)
        expect(trm).to match(/\bGroup Total\b/)
        expect(trm).to match(/\bGrp Std Dev\b/)
      end

      it 'should be able to display colors and decorations' do
        fmt = TermFormatter.new(@tab, framecolor: 'black.yellow') do |t|
          t.format_for(:header, string: 'BCc[tomato.white]')
          t.format_for(:body, string: 'c[.yellow]', boolean: 'c[green.yellow,red.yellow]',
                       numeric: 'Rc[purple]', shares: 'R0.0,', ref: '5.0')
        end
        trm = fmt.output
        expect(trm).to match(/\e\[30m\e\[43m╒═════/)
        expect(trm).to match(/\e\[31m\e\[43m F    \e\[0m/)
        expect(trm).to match(/\e\[32m\e\[43m T    \e\[0m/)
      end

      it 'should be able to display to term after forcing a column to string' do
        rows = [
          {ref: 1, date: '2013-05-02', code: 'P', raw: 795_546.20,
           shares: 795_546.2, price: 1.1850, info: 'ZMPEF1', bool: 'T'},
          {ref: 2, date: '2013-05-02', code: 'P', raw: 'ChgToStr',
           shares: 118_186.4, price: 11.8500, info: 'ZMPEF1', bool: 'T'},
          {ref: 5, date: '2013-05-02', code: 'P', raw: 118_186.40,
           shares: 118_186.4, price: 11.8500, info: 'ZMPEF1\'s "Ent"', bool: 'T'},
          {ref: 16, date: '2013-05-30', code: 'S', raw: 6_679.00,
           shares: 2808.52, price: 25.0471, info: 'ZMEAC', bool: 'T'}
        ]
        heads = rows[0].keys
        tab = Table.new
        heads.each do |h|
          tab.add_column(Column.new(header: h))
        end
        tab.force_string!(:raw, :shares)
        rows.each do |r|
          tab << r
        end
        out = tab.to_term { |f| f.format_for(:body, numeric: 'C,0.1') }
        expect(out).to match(/11.9/)
        expect(out).to match(/118186\.4/)
      end
    end
  end
end
