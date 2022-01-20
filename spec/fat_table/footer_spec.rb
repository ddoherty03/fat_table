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

      describe 'initialization' do
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

        it 'returns Column for each header' do
          expect(foot.column(:a)).to be_a_kind_of(Column)
          expect(foot.column(:b)).to be_a_kind_of(Column)
          expect(foot.column(:c)).to be_a_kind_of(Column)
          expect(foot.column(:d)).to be_a_kind_of(Column)
        end
      end

      describe 'aggregators' do
        let(:tab) {
          aoh = [
            { a: '5', b: true, c: '3123', d: '[2021-03-17]', s: 'Four' },
            { a: '4', b: 'T', c: 6412, d: '[1957-09-22]', s: 'score' },
            { a: '7', b: 'No', c: '$1888.88', d: '<2022-01-08>', s: 'and seven' },
          ]
          Table.from_aoh(aoh)
        }

        it 'computes a symbolic aggregator' do
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:a, :sum)
          expect(f.a).to eq(16)
        end

        it 'computes a string as value aggregator' do
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:a, '314.59')
          expect(f.a).to eq(314.59)
        end

        it 'computes a fixed string as value aggregator' do
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:a, 'Merry Christmas')
          expect(f.a).to eq('Merry Christmas')
        end

        it 'can use a Ruby object as aggregator' do
          f = Footer.new('Summary', tab, label_col: :s)
          f.add_value(:d, Date.today)
          expect(f.d).to eq(Date.today)
        end

        it 'computes a lambda aggregator' do
          foot = Footer.new('Summary', tab, label_col: :s)
          foot.add_value(:a, ->(f, c) { f.items(c).inject(&:*) })
          expect(foot.a).to eq(5 * 4 * 7)
          foot.add_value(:c, ->(f, c) { f.items(c).map { |x| x*x }.sum.sqrt(12) })
          expect(foot.c).to be_within(0.001).of(7377.99)
        end

        it 'lambda rejects incompatible types' do
          foot = Footer.new('Summary', tab, label_col: :s)
          expect {
            foot.add_value(:a, ->(f, _c) { f.table })
          }.to raise_error(/lambda cannot return/)
        end
      end
    end

    context 'group footers' do
      describe 'initialization' do
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

      describe 'group accessor methods' do
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

        let(:foot) {
          f = Footer.new('Summary', tab, group: true)
          f.add_value(:shares, :sum)
          f.add_value(:bool, :all?)
          f.add_value(:price, :avg)
          f.add_value(:date, :min)
          f
        }

        it 'defines an accessor method for each column' do
          expect(foot.shares).to eq([795546.20, 158974.9, 62789.48, 2808.52])
          expect(foot.bool).to eq([true, false, false, true])
          expect(foot.price.map { |x| x.round(5).to_f}).to eq([1.1850, 22.8176, 25.97551, 25.0471])
          expect(foot.date).to eq([Date.parse('2013-05-02'), Date.parse('2013-05-02'),
                                   Date.parse('2013-05-20'), Date.parse('2013-05-30')])
        end

        it 'allows access by brackets' do
          expect(foot[:shares]).to eq([795546.20, 158974.9, 62789.48, 2808.52])
          expect(foot[:bool]).to eq([true, false, false, true])
          expect(foot[:price].map { |x| x.round(5).to_f}).to eq([1.1850, 22.8176, 25.97551, 25.0471])
          expect(foot[:date]).to eq([Date.parse('2013-05-02'), Date.parse('2013-05-02'),
                                     Date.parse('2013-05-20'), Date.parse('2013-05-30')])
        end

        it 'produces itself as a hash' do
          h = foot.to_h(2)
          expect(h[:shares]).to eq(62789.48)
          expect(h[:bool]).to eq(false)
          expect(h[:price].round(5)).to eq(25.97551)
          expect(h[:date]).to eq(Date.parse('2013-05-20'))
        end

        it 'returns Column for sub-groups' do
          foot.number_of_groups.times do |k|
            expect(foot.column(:shares, k)).to be_a_kind_of(Column)
            expect(foot.column(:bool, k)).to be_a_kind_of(Column)
            expect(foot.column(:price, k)).to be_a_kind_of(Column)
            expect(foot.column(:date, k)).to be_a_kind_of(Column)
          end
          expect { foot.column(:shares) }.to raise_error(/missing the group number/)
        end

        it 'returns the items for sub-groups' do
          foot.number_of_groups.times do |k|
            expect(foot.column(:shares, k)).to be_a_kind_of(Column)
            expect(foot.column(:bool, k)).to be_a_kind_of(Column)
            expect(foot.column(:price, k)).to be_a_kind_of(Column)
            expect(foot.column(:date, k)).to be_a_kind_of(Column)
          end
        end
      end

      describe 'group aggregators' do
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
        let(:foot) {
          Footer.new('Summary', tab, group: true)
        }

        it 'computes a symbolic aggregator' do
          foot.add_value(:raw, :sum)
          expect(foot.raw[0]).to eq(795546.2)
          expect(foot.raw[1]).to eq(215186.4)
          expect(foot.raw[2]).to eq(149321.0)
          expect(foot.raw[3]).to eq(6679.0)
        end

        it 'computes a string as value aggregator' do
          foot.add_value(:raw, '314.59')
          expect(foot.raw[0]).to eq(314.59)
          expect(foot.raw[1]).to eq(314.59)
          expect(foot.raw[2]).to eq(314.59)
          expect(foot.raw[3]).to eq(314.59)
        end

        it 'computes a fixed string as value aggregator' do
          foot.add_value(:raw, 'Merry Christmas')
          expect(foot.raw[0]).to eq('Merry Christmas')
          expect(foot.raw[1]).to eq('Merry Christmas')
          expect(foot.raw[2]).to eq('Merry Christmas')
          expect(foot.raw[3]).to eq('Merry Christmas')
        end

        it 'can use a Ruby object as aggregator' do
          foot.add_value(:date, Date.today)
          expect(foot.date[0]).to eq(Date.today)
          expect(foot.date[1]).to eq(Date.today)
          expect(foot.date[2]).to eq(Date.today)
          expect(foot.date[3]).to eq(Date.today)
        end

        it 'computes a lambda aggregator' do
          foot.add_value(:raw, ->(f, c, k) { f.items(c, k).map { |x| x*x }.sum.sqrt(12) })
          expect(foot.raw[0]).to be_within(0.0001).of(795546.2)
          expect(foot.raw[1]).to be_within(0.0001).of(146071.986175)
          expect(foot.raw[2]).to be_within(0.0001).of(63066.9773891)
          expect(foot.raw[3]).to be_within(0.0001).of(6679.0)
        end

        it 'lambda rejects incompatible types' do
          expect {
            foot.add_value(:shares, ->(f, c, k) { f.table })
          }.to raise_error(/lambda cannot return/)
        end
      end
    end

    context 'problematic code' do
      let(:tab_a) {
        tab_a_str = <<-EOS
    | Id | Name  | Age | Address    | Salary |  Join Date |
    |----+-------+-----+------------+--------+------------|
    |  1 | Paul  |  32 | California |  20000 | 2001-07-13 |
    |  3 | Teddy |  23 | Norway     |  20000 | 2007-12-13 |
    |  4 | Mark  |  25 | Rich-Mond  |  65000 | 2007-12-13 |
    |  5 | David |  27 | Texas      |  85000 | 2007-12-13 |
    |  2 | Allen |  25 | Texas      |        | 2005-07-13 |
    |  8 | Paul  |  24 | Houston    |  20000 | 2005-07-13 |
    |  9 | James |  44 | Norway     |   5000 | 2005-07-13 |
    | 10 | James |  45 | Texas      |   5000 |            |
    EOS
        FatTable.from_org_string(tab_a_str)
      }

      it 'tallies the count' do
        tab_a.to_text do |f|
          f.footer('Average', age: :avg, salary: :avg, join_date: :avg)
          f.footer('Tally', name: :count)
          f.format(numeric: '0.0R,', datetime: 'D[%v]')
        end
      end

      it 'orders by year' do
        tab_x =
          tab_a.select(:id, :name, :age, :address, :salary,
                       :join_date, year: 'join_date ? join_date.year : 0')
            .order_by(:year)
        true
      end

      it 'select eval with nils' do
        tab_x =
          tab_a.select(:id, :name, :age, :address, :salary,
                       :join_date, year: 'join_date.year')
            .order_by(:year)
        true
      end
    end
  end
end
