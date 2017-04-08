require 'spec_helper'

module FatCore
  describe AoaFormatter do
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
        aoa = AoaFormatter.new(@tab).output
        expect(aoa.class).to eq(Array)
        expect(aoa.first.class).to eq(Array)
      end

      it 'should be able to set format and output by method calls' do
        fmt = AoaFormatter.new(@tab)
        fmt.format(ref: '5.0', code: 'C', raw: ',0.0R', shares: ',0.0R',
                   price: '0.3', bool: 'Y')
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        aoa = fmt.output
        expect(aoa.size).to eq(45)
        expect(aoa.first.first).to eq('Ref')
        expect(aoa.first.last).to eq('Bool')
        expect(aoa[1]).to be_nil
        expect(aoa[2][0]).to eq('00001')
        expect(aoa[2][1]).to eq('2013-05-02')
        expect(aoa[2][2]).to eq('P')
        expect(aoa[2][3]).to eq('795,546')
        expect(aoa[2][4]).to eq('795,546')
        expect(aoa[2][5]).to eq('1.185')
        expect(aoa[2][6]).to eq('ZMPEF1')
        expect(aoa[2][7]).to eq('Y')
        expect(aoa[6][0]).to eq('Group Total')
        expect(aoa[6][3]).to eq('1,031,919')
        expect(aoa[6][4]).to eq('1,031,919')
        expect(aoa[6][5]).to eq('24.885')
      end
    end
  end
end
