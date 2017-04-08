require 'spec_helper'

module FatCore
  describe AohFormatter do
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
        aoh = AohFormatter.new(@tab).output
        expect(aoh.class).to eq(Array)
        expect(aoh.first.class).to eq(Hash)
      end

      it 'should be able to set format and output by method calls' do
        fmt = AohFormatter.new(@tab)
        fmt.format(ref: '5.0', code: 'C', raw: ',0.0R', shares: ',0.0R',
                   price: '0.3', bool: 'Y')
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        aoh = fmt.output
        expect(aoh.size).to eq(43)
        expect(aoh.first.keys.first).to eq(:ref)
        expect(aoh.first.keys.last).to eq(:bool)
        expect(aoh[0][:ref]).to eq('00001')
        expect(aoh[0][:date]).to eq('2013-05-02')
        expect(aoh[0][:code]).to eq('P')
        expect(aoh[0][:raw]).to eq('795,546')
        expect(aoh[0][:shares]).to eq('795,546')
        expect(aoh[0][:price]).to eq('1.185')
        expect(aoh[0][:info]).to eq('ZMPEF1')
        expect(aoh[0][:bool]).to eq('Y')
        expect(aoh[4][:ref]).to eq('Group Total')
        expect(aoh[4][:shares]).to eq('1,031,919')
        expect(aoh[4][:raw]).to eq('1,031,919')
        expect(aoh[4][:price]).to eq('24.885')
      end
    end
  end
end
