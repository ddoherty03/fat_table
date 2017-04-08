require 'spec_helper'

module FatCore
  describe TextFormatter do
    describe 'table output' do
      before :each do
        @aoa =
          [['Ref', 'Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
           nil,
           [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
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
      end

      it 'should be able to output a table with default formatting instructions' do
        txt = TextFormatter.new(@tab).output
        expect(txt.class).to eq(String)
      end

      it 'should be able to set format and output by method calls' do
        fmt = TextFormatter.new(@tab)
        fmt.format(ref: '5.0', code: 'C', raw: ',0.0', shares: ',0.0',
                   price: '0.3R', bool: 'Y', numeric: 'R')
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        txt = fmt.output
        expect(txt.size).to be > 1000
        expect(txt).to match(/\bRef\b/)
        expect(txt).to match(/\bBool\b/)
        expect(txt).to match(/\b2013-05-02\b/)
        expect(txt).to match(/^\+[=+]+\+$/)
        expect(txt).to match(/^\+[-+]+\+$/)
        expect(txt).to match(/\D795,546\D/)
        expect(txt).to match(/\D1,031,919\D/)
        expect(txt).to match(/\D1.185\D/)
        expect(txt).to match(/\D24.885\D/)
        expect(txt).to match(/\D00001\D/)
        expect(txt).to match(/\bY\b/)
        expect(txt).to match(/\bP\b/)
        expect(txt).to match(/\bZMPEF1\b/)
        expect(txt).to match(/\bGroup Total\b/)
        expect(txt).to match(/\bGrp Std Dev\b/)
      end
    end
  end
end
