module FatTable
  RSpec.describe 'Footer' do
    context 'non-group footers' do
      let(:tab) {
        aoh = [
          { a: '5', b: true, 'Somenum' => '20', s: '5143',
            c: '3123', d: '[2021-03-17]' },
          { a: '4', b: 'T', 'Somenum' => '5',  s: 412,
            c: 6412, d: '1957-09-22]'},
          { a: '7', b: 'No', 'Somenum' => '8',  s: '$1821',
            c: '$1888', d: '<2022-01-08>' },
        ]
        Table.from_aoh(aoh)
      }

      describe 'initialization of Footer' do
        it 'initializes an empty footer' do
          f = Footer.new('Maximum', tab, label_col: :d)
          expect(f.label).to eq('Maximum')
          expect(f.table).to eq(tab)
          expect(f.label_col).to eq(:d)
          expect(f.group).to be false
          expect(f.values[:d]).to eq(['Maximum'])
        end

        it 'initializes a footer for a single column' do
          f = Footer.new('Minimum', tab, label_col: :d)
          f.add_value(:a, :min)
          expect(f[:a]).to eq(4)
          expect(f['a']).to eq(4)
          expect(f[:d]).to eq('Minimum')
          expect(f['d']).to eq('Minimum')
        end

        it 'initializes a footer for a multiple columns' do
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:a, :max)
          f.add_value(:b, :all?)
          f.add_value(:somenum, :avg)
          f.add_value(:c, :range)
          f.add_value(:d, :min)
          expect(f[:s]).to eq('Summary')
          expect(f[:a]).to eq(7)
          expect(f[:b]).to eq(false)
          expect(f['Somenum']).to eq(11)
          expect(f['c']).to eq((1888..6412))
          expect(f[:d]).to eq(Date.parse('1957-09-22'))
        end
      end
    end

    context 'group footers' do
      let(:tab) {
        @aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          nil,
          [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
          nil,
          [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1', 'T'],
          [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ZMEAC', 'F'],
          [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ZMEAC', 'T'],
          nil,
          [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ZMEAC', 'T'],
          [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ZMEAC', 'T'],
          [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ZMEAC', 'F'],
          [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ZMEAC', 'T'],
          [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ZMEAC', 'T'],
          [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ZMEAC', 'F'],
          [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ZMEAC', 'T'],
          nil,
          [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T'],
        ]
        Table.from_aoa(@aoa, hlines: true)
      }

      it 'initializes an empty group footer' do
        g = Footer.new('Summary', tab, label_col: :ref, group: true)
        expect(g.label).to eq('Summary')
        expect(g.table).to eq(tab)
        expect(g.label_col).to eq(:ref)
        expect(g.group).to be true
        expect(g.number_of_groups).to eq(4)
      end

      it 'initializes adds a single value to a group footer' do
        g = Footer.new('Summary', tab, label_col: :ref, group: true)
        g.add_value(:shares, :sum)
        expect(g[0][:shares]).to eq(795246.2)
        expect(g[:shares][0]).to eq(795246.2)
      end
    end
  end
end
