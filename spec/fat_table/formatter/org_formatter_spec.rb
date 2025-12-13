# frozen_string_literal: true

module FatTable
  RSpec.describe 'Formatter::OrgFormatter' do
    describe 'table output' do
      let(:tab) do
        aoa = [
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
        Table.from_aoa(aoa).order_by(:date)
      end

      it 'outputs a table with default formatting' do
        org = OrgFormatter.new(tab).output
        expect(org.class).to eq(String)
      end

      it 'is able to set format and output by method calls' do
        fmt = OrgFormatter.new(tab)
        fmt.format(
          ref: '5.0',
          code: 'C',
          raw: ',0.0',
          shares: ',0.0',
          price: '0.3R',
          bool: 'Y',
          numeric: 'R',
        )
        fmt.format_for(:header, string: 'CB')
        fmt.sum_gfooter(:price, :raw, :shares)
        fmt.gfooter('Grp Std Dev', price: :dev, shares: :dev, bool: :one?)
        fmt.sum_footer(:price, :raw, :shares)
        fmt.footer('Std Dev', price: :dev, shares: :dev, bool: :all?)
        fmt.footer('Any?', bool: :any?)
        org = fmt.output
        expect(org.size).to be > 1000
        expect(org).to match(/\bRef\b/)
        expect(org).to match(/\bBool\b/)
        expect(org).to match(/\[2013-05-02 Thu\]/)
        expect(org).to match(/^\|[-+]+\|$/)
        expect(org).to match(/\D795,546\D/)
        expect(org).to match(/\D1,031,919\D/)
        expect(org).to match(/\D1.185\D/)
        expect(org).to match(/\D24.885\D/)
        expect(org).to match(/\D00001\D/)
        expect(org).to match(/\bY\b/)
        expect(org).to match(/\bP\b/)
        expect(org).to match(/\bZMPEF1\b/)
        expect(org).to match(/\bGroup Total\b/)
        expect(org).to match(/\bGrp Std Dev\b/)
      end
    end

    describe 'Module level formatter' do
      let(:tab) do
        aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          [1,  '2013-05-02', 'P', 795_546.203, 795_546.2, 1.1850,  'ZMPEF1', 'T'],
          [2,  '2013-05-02', 'P', 118_186.40,  118_186.4, 11.8500, 'ZMPEF1', 'T'],
          [7,  '2013-05-20', 'S', 12_000.00,   5046.00,   28.2804, 'ZMEAC',  'F'],
          [8,  '2013-05-20', 'S', 85_000.00,   35_742.50, 28.3224, 'ZMEAC',  'T'],
          [9,  '2013-05-20', 'S', 33_302.00,   14_003.49, 28.6383, 'ZMEAC',  'T'],
          [10, '2013-05-23', 'S', 8000.00,     3364.00,   27.1083, 'ZMEAC',  'T'],
          [11, '2013-05-23', 'S', 23_054.00,   9694.21,   26.8015, 'ZMEAC',  'F'],
          [12, '2013-05-23', 'S', 39_906.00,   16_780.47, 25.1749, 'ZMEAC',  'T'],
          [13, '2013-05-29', 'S', 13_459.00,   5659.51,   24.7464, 'ZMEAC',  'T'],
          [14, '2013-05-29', 'S', 15_700.00,   6601.85,   24.7790, 'ZMEAC',  'F'],
          [15, '2013-05-29', 'S', 15_900.00,   6685.95,   24.5802, 'ZMEAC',  'T'],
          [16, '2013-05-30', 'S', 6_679.00,    2808.52,   25.0471, 'ZMEAC',  'T']
        ]
        FatTable::Table.from_aoa(aoa).order_by(:date)
      end

      it 'formats with FatTable.to_org' do
        tab1 = tab.select(
          :ref,
          :price,
          :shares,
          traded_on: :date,
          cost: 'price * shares',
          cumulative: '@total_cost',
          ivars: { total_cost: 0 },
          before_hook: '@total_cost += price * shares',
        )
        tab_org = FatTable.to_org(tab1) do |f|
          f.format(price: '0.4', shares: '0.0,', cost: '0.2,', cumulative: '0.2,')
        end
        expect(tab_org).to be_an(String)
        expect(tab_org).to match(/\|[-+]+\|/)
      end
    end
  end
end
