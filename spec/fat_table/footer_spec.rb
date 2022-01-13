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

      describe 'accessor methods' do
        let(:tab) {
          aoh = [
            { a: '5', b: true, c: '3123', d: '[2021-03-17]', s: 'Four' },
            { a: '4', b: 'T', c: 6412, d: '[1957-09-22]', s: 'score' },
            { a: '7', b: 'No', c: '$1888', d: '<2022-01-08>', s: 'and seven' },
          ]
          Table.from_aoh(aoh)
        }

        let(:foot) {
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:a, :sum)
          f.add_value(:b, :all?)
          f.add_value(:c, :avg)
          f.add_value(:d, :min)
          f
        }

        it 'defines an accessor for each column' do
          expect(foot.a).to eq(16)
          expect(foot.b).to eq(false)
          expect(foot.c.round(1)).to eq(3807.7)
          expect(foot.d).to eq(Date.parse('1957-09-22'))
        end

        it 'allows access by brackets' do
          expect(foot[:a]).to eq(16)
          expect(foot[:b]).to eq(false)
          expect(foot[:c].round(1)).to eq(3807.7)
          expect(foot[:d]).to eq(Date.parse('1957-09-22'))
        end

        it 'produces itself as a hash' do
          h = foot.to_h
          expect(h[:a]).to eq(16)
          expect(h[:b]).to eq(false)
          expect(h[:c].round(1)).to eq(3807.7)
          expect(h[:d]).to eq(Date.parse('1957-09-22'))
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
        g = Footer.new('Summary', tab, label_col: :date, group: true)
        expect(g.label).to eq('Summary')
        expect(g.table).to eq(tab)
        expect(g.label_col).to eq(:date)
        expect(g.group).to be true
        expect(g.number_of_groups).to eq(4)
      end

      it 'places label in first column by default' do
        g = Footer.new('Summary', tab, group: true)
        expect(g.label).to eq('Summary')
        expect(g.table).to eq(tab)
        expect(g.label_col).to eq(:ref)
        expect(g.group).to be true
        expect(g.number_of_groups).to eq(4)
      end

      it 'adds a single value to a group footer' do
        g = Footer.new('Summary', tab, label_col: :ref, group: true)
        g.add_value(:shares, :sum)
        expect(g[:shares][0]).to eq(BigDecimal('795546.2'))
        expect(g[:shares][1]).to eq(BigDecimal('158974.9'))
        expect(g[:shares][2]).to eq(BigDecimal('62789.48'))
        expect(g[:shares][3]).to eq(BigDecimal('2808.52'))
      end

      it 'adds multiple values to a group footer' do
        g = Footer.new('Summary', tab, label_col: :ref, group: true)
        g.add_value(:shares, :sum)
        expect(g[:shares][0]).to eq(BigDecimal('795546.2'))
        expect(g[:shares][1]).to eq(BigDecimal('158974.9'))
        expect(g[:shares][2]).to eq(BigDecimal('62789.48'))
        expect(g[:shares][3]).to eq(BigDecimal('2808.52'))

        g.add_value(:date, :avg)
        expect(g[:date][0].year).to eq(2013)
        expect(g[:date][1].year).to eq(2013)
        expect(g[:date][2].year).to eq(2013)
        expect(g[:date][3].year).to eq(2013)

        g.add_value(:price, :avg)
        delta = 0.00001
        expect(g[:price][0]).to be_within(delta).of(BigDecimal('1.1850'))
        expect(g[:price][1]).to be_within(delta).of(BigDecimal('22.8176'))
        expect(g[:price][2]).to be_within(delta).of(BigDecimal('25.97551'))
        expect(g[:price][3]).to be_within(delta).of(BigDecimal('25.0471'))

        g.add_value(:bool, :all?)
        expect(g[:bool][0]).to eq(true)
        expect(g[:bool][1]).to eq(false)
        expect(g[:bool][2]).to eq(false)
        expect(g[:bool][3]).to eq(true)
      end
    end
  end
end
