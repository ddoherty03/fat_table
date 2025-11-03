# frozen_string_literal: true

module FatTable
  RSpec.describe 'Footer' do
    context 'with non-group footers' do
      let(:tab) do
        aoh = [
          {
            a: '5',
            b: true,
            'Somenum' => '20',
            s: '5143',
            c: '3123',
            d: '[2021-03-17]'
          },
          {
            a: '4',
            b: 'T',
            'Somenum' => '5',
            s: 412,
            c: 6412,
            d: '1957-09-22]'
          },
          {
            a: '7',
            b: 'No',
            'Somenum' => '8',
            s: '$1821',
            c: '$1888',
            d: '<2022-01-08>'
          },
        ]
        Table.from_aoh(aoh)
      end

      describe 'initialization' do
        it 'initializes an empty footer' do
          f = Footer.new(tab, label: 'Maximum', label_col: :d)
          expect(f.label).to eq('Maximum')
          expect(f.table).to eq(tab)
          expect(f.label_col).to eq(:d)
          expect(f.group).to be false
          expect(f.values[:d]).to eq(['Maximum'])
        end

        it 'initializes a footer for a single column' do
          f = Footer.new(tab, label: 'Minimum', label_col: :d)
          f.add_value(:a, :min)
          expect(f[:a]).to eq(4)
          expect(f['a']).to eq(4)
          expect(f[:d]).to eq('Minimum')
          expect(f['d']).to eq('Minimum')
        end

        it 'initializes a footer for a multiple columns' do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:a, :max)
          f.add_value(:b, :all?)
          f.add_value(:somenum, :avg)
          f.add_value(:c, :range)
          f.add_value(:d, :min)
          expect(f[:s]).to eq('Summary')
          expect(f[:a]).to eq(7)
          expect(f[:b]).to be(false)
          expect(f['Somenum']).to eq(11)
          expect(f['c']).to eq(1888..6412)
          expect(f[:d]).to eq(Date.parse('1957-09-22'))
        end
      end

      describe 'accessor methods' do
        let(:tab) do
          aoh = [
            { a: '5', b: true, c: '3123', d: '[2021-03-17]', s: 'Four' },
            { a: '4', b: 'T', c: 6412, d: '[1957-09-22]', s: 'score' },
            { a: '7', b: 'No', c: '$1888', d: '<2022-01-08>', s: 'and seven' },
          ]
          Table.from_aoh(aoh)
        end

        let(:foot) do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:a, :sum)
          f.add_value(:b, :all?)
          f.add_value(:c, :avg)
          f.add_value(:d, :min)
          f
        end

        it 'defines an accessor for each column' do
          expect(foot.a).to eq(16)
          expect(foot.b).to be(false)
          expect(foot.c.round(1)).to eq(3807.7)
          expect(foot.d).to eq(Date.parse('1957-09-22'))
        end

        it 'allows access by brackets' do
          expect(foot[:a]).to eq(16)
          expect(foot[:b]).to be(false)
          expect(foot[:c].round(1)).to eq(3807.7)
          expect(foot[:d]).to eq(Date.parse('1957-09-22'))
        end

        it 'produces itself as a hash' do
          h = foot.to_h
          expect(h[:a]).to eq(16)
          expect(h[:b]).to be(false)
          expect(h[:c].round(1)).to eq(3807.7)
          expect(h[:d]).to eq(Date.parse('1957-09-22'))
        end

        it 'returns Column for each header' do
          expect(foot.column(:a)).to be_a(Column)
          expect(foot.column(:b)).to be_a(Column)
          expect(foot.column(:c)).to be_a(Column)
          expect(foot.column(:d)).to be_a(Column)
        end
      end

      describe 'aggregators' do
        let(:tab) do
          aoh = [
            { a: '5', b: true, c: '3123', d: '[2021-03-17]', s: 'Four' },
            { a: '4', b: 'T', c: 6412, d: '[1957-09-22]', s: 'score' },
            { a: '7', b: 'No', c: '$1888.88', d: '<2022-01-08>', s: 'and seven' },
          ]
          Table.from_aoh(aoh)
        end

        it 'computes a symbolic aggregator' do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:a, :sum)
          expect(f.a).to eq(16)
        end

        it 'computes a string as value aggregator' do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:a, '314.59')
          expect(f.a).to eq(314.59)
        end

        it 'computes a fixed string as value aggregator' do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:a, 'Merry Christmas')
          expect(f.a).to eq('Merry Christmas')
        end

        it 'can use a Ruby object as aggregator' do
          f = Footer.new(tab, label: 'Summary', label_col: :s)
          f.add_value(:d, Date.today)
          expect(f.d).to eq(Date.today)
        end

        it 'computes a lambda aggregator' do
          foot = Footer.new(tab, label: 'Summary', label_col: :s)
          foot.add_value(:a, ->(c) { c.items.inject(&:*) })
          expect(foot.a).to eq(5 * 4 * 7)
          foot.add_value(:c, ->(c) { c.items.sum { |x| x * x }.sqrt(12) })
          expect(foot.c).to be_within(0.001).of(7377.99)
        end

        it 'lambda converts incompatible types to inspect strings' do
          foot = Footer.new(tab, label: 'Summary', label_col: :s)
          foot.add_value(:a, ->(_c, f) { f.table })
          expect(foot[:a]).to match(/FatTable::Table/)
        end
      end

      describe 'dynamic labels' do
        it 'calculates labels from a zero-argument lambda' do
          f = Footer.new(tab, label: -> { "As of #{Date.parse('1957-09-22')}" })
          expect(f.label_col).to eq(:a)
          expect(f.group).to be false
          expect(f.label).to match(/as of.*1957/i)
        end

        it 'calculates labels from a one-argument lambda' do
          f = Footer.new(tab, label: ->(f) { "Summary of #{f.table.size} rows" })
          expect(f.table).to eq(tab)
          expect(f.label_col).to eq(:a)
          expect(f.group).to be false
          expect(f.number_of_groups).to eq(1)
          expect(f.label).to match(/Summary of 3 rows/i)
        end

        it 'raises error for labels from a two-argument lambda' do
          expect { Footer.new(tab, label: ->(k, f) { "#{k} of #{f.table.size}" }) }
            .to raise_error(/label proc may only have 1/)
        end
      end
    end

    context 'with group footers' do
      describe 'initialization' do
        let(:tab) do
          aoa = [
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
          Table.from_aoa(aoa, hlines: true)
        end

        it 'initializes an empty group footer' do
          g = Footer.new(tab, label: 'Summary', label_col: :date, group: true)
          expect(g.label).to eq('Summary')
          expect(g.table).to eq(tab)
          expect(g.label_col).to eq(:date)
          expect(g.group).to be true
          expect(g.number_of_groups).to eq(4)
        end

        it 'places label in first column by default' do
          g = Footer.new(tab, label: 'Summary', group: true)
          expect(g.label).to eq('Summary')
          expect(g.table).to eq(tab)
          expect(g.label_col).to eq(:ref)
          expect(g.group).to be true
          expect(g.number_of_groups).to eq(4)
        end

        it 'calculates group labels from a zero-argument lambda' do
          g = Footer.new(tab, label: -> { "Group as of #{Date.parse('1957-09-22')}" }, group: true)
          expect(g.table).to eq(tab)
          expect(g.label_col).to eq(:ref)
          expect(g.group).to be true
          expect(g.number_of_groups).to eq(4)
          g.number_of_groups.times do |k|
            expect(g.label(k)).to match(/group.*1957/i)
          end
        end

        it 'calculates group labels from a one-argument lambda' do
          g = Footer.new(tab, label: ->(k) { "Group #{k}" }, group: true)
          expect(g.table).to eq(tab)
          expect(g.label_col).to eq(:ref)
          expect(g.group).to be true
          expect(g.number_of_groups).to eq(4)
          g.number_of_groups.times do |k|
            expect(g.label(k)).to match(/group #{k}/i)
          end
        end

        it 'calculates group labels from a two-argument lambda' do
          g = Footer.new(
            tab,
            label: ->(k, f) { "Group #{k} as of #{f.column(:date, k).max}" },
            group: true,
          )
          expect(g.table).to eq(tab)
          expect(g.label_col).to eq(:ref)
          expect(g.group).to be true
          expect(g.number_of_groups).to eq(4)
          g.number_of_groups.times do |k|
            expect(g.label(k)).to match(/group #{k}/i)
          end
        end

        it 'adds a single value to a group footer' do
          g = Footer.new(tab, label: 'Summary', label_col: :ref, group: true)
          g.add_value(:shares, :sum)
          expect(g[:shares][0]).to eq(BigDecimal('795546.2'))
          expect(g[:shares][1]).to eq(BigDecimal('158974.9'))
          expect(g[:shares][2]).to eq(BigDecimal('62789.48'))
          expect(g[:shares][3]).to eq(BigDecimal('2808.52'))
        end

        it 'adds multiple values to a group footer' do
          g = Footer.new(tab, label: 'Summary', label_col: :ref, group: true)
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
          expect(g[:bool][0]).to be(true)
          expect(g[:bool][1]).to be(false)
          expect(g[:bool][2]).to be(false)
          expect(g[:bool][3]).to be(true)
        end
      end

      describe 'group accessor methods' do
        let(:tab) do
          aoa = [
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
          Table.from_aoa(aoa, hlines: true)
        end

        let(:foot) do
          f = Footer.new(tab, label: 'Summary', group: true)
          f.add_value(:shares, :sum)
          f.add_value(:bool, :all?)
          f.add_value(:price, :avg)
          f.add_value(:date, :min)
          f
        end

        it 'defines an accessor method for each column' do
          expect(foot.shares).to eq([795546.20, 158974.9, 62789.48, 2808.52])
          expect(foot.bool).to eq([true, false, false, true])
          expect(foot.price.map { |x| x.round(5).to_f }).to eq([1.1850, 22.8176, 25.97551, 25.0471])
          expect(foot.date).to eq([
            Date.parse('2013-05-02'),
            Date.parse('2013-05-02'),
            Date.parse('2013-05-20'),
            Date.parse('2013-05-30')
          ])
        end

        it 'allows access by brackets' do
          expect(foot[:shares]).to eq([795546.20, 158974.9, 62789.48, 2808.52])
          expect(foot[:bool]).to eq([true, false, false, true])
          expect(foot[:price].map { |x| x.round(5).to_f }).to eq([1.1850, 22.8176, 25.97551, 25.0471])
          expect(foot[:date]).to eq([
            Date.parse('2013-05-02'),
            Date.parse('2013-05-02'),
            Date.parse('2013-05-20'),
            Date.parse('2013-05-30')
          ])
        end

        it 'produces itself as a hash' do
          h = foot.to_h(2)
          expect(h[:shares]).to eq(62789.48)
          expect(h[:bool]).to be(false)
          expect(h[:price].round(5)).to eq(25.97551)
          expect(h[:date]).to eq(Date.parse('2013-05-20'))
        end

        it 'returns Column for sub-groups' do
          foot.number_of_groups.times do |k|
            expect(foot.column(:shares, k)).to be_a(Column)
            expect(foot.column(:bool, k)).to be_a(Column)
            expect(foot.column(:price, k)).to be_a(Column)
            expect(foot.column(:date, k)).to be_a(Column)
          end
          expect { foot.column(:shares) }.to raise_error(/missing the group number/)
        end

        it 'returns the items for sub-groups' do
          foot.number_of_groups.times do |k|
            expect(foot.column(:shares, k)).to be_a(Column)
            expect(foot.column(:bool, k)).to be_a(Column)
            expect(foot.column(:price, k)).to be_a(Column)
            expect(foot.column(:date, k)).to be_a(Column)
          end
        end
      end

      describe 'group aggregators' do
        let(:tab) do
          aoa = [
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
          Table.from_aoa(aoa, hlines: true)
        end
        let(:foot) do
          Footer.new(tab, label: 'Summary', group: true)
        end

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
          foot.add_value(:raw, ->(k, c, f) { f.table[:raw].sum { |x| x * x * (k + 1) / c.count }.sqrt(12) })
          expect(foot.raw[0]).to be_within(0.0001).of(811327.8216)
          expect(foot.raw[1]).to be_within(0.0001).of(662446.3924)
          expect(foot.raw[2]).to be_within(0.0001).of(531138.73658)
          expect(foot.raw[3]).to be_within(0.0001).of(1622655.6433)
        end

        it 'lambda converts incompatible types to inspect strings' do
          foot.add_value(:shares, ->(_k, _c, f) { f.table })
          expect(foot[:shares][0]).to match(/FatTable::Table/)
          expect(foot[:shares][1]).to match(/FatTable::Table/)
          expect(foot[:shares][2]).to match(/FatTable::Table/)
          expect(foot[:shares][3]).to match(/FatTable::Table/)
        end
      end
    end

    context 'with problematic code' do
      let(:tab_a) do
        tab_a_str = <<~EOS
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
      end

      it 'tallies the count' do
        expected = <<~TAB
          +=========+=======+=====+============+========+=============+
          | Id      | Name  | Age | Address    | Salary | Join Date   |
          +---------+-------+-----+------------+--------+-------------+
          |       1 | Paul  |  32 | California | 20,000 | 2001-07-13  |
          |       3 | Teddy |  23 | Norway     | 20,000 | 2007-12-13  |
          |       4 | Mark  |  25 | Rich-Mond  | 65,000 | 2007-12-13  |
          |       5 | David |  27 | Texas      | 85,000 | 2007-12-13  |
          |       2 | Allen |  25 | Texas      |        | 2005-07-13  |
          |       8 | Paul  |  24 | Houston    | 20,000 | 2005-07-13  |
          |       9 | James |  44 | Norway     |  5,000 | 2005-07-13  |
          |      10 | James |  45 | Texas      |  5,000 |             |
          +---------+-------+-----+------------+--------+-------------+
          | Average |       |  31 |            | 31,429 | 29-DEC-2005 |
          +---------+-------+-----+------------+--------+-------------+
          |   Tally | 8     |     |            |        |             |
          +=========+=======+=====+============+========+=============+
        TAB
        txt = tab_a.to_text do |f|
          f.footer('Average', age: :avg, salary: :avg, join_date: :avg)
          f.footer('Tally', name: :count)
          f.format(numeric: '0.0R,', datetime: 'D[%v]')
        end
        expect(txt).to eq(expected)
      end

      it 'orders by year' do
        res = tab_a.select(
          :id,
          :name,
          :age,
          :address,
          :salary,
          :join_date,
          year: 'join_date ? join_date.year : 0',
        ).order_by(:year)
        expected = [0, 2001, 2005, 2005, 2005, 2007, 2007, 2007]
        expect(res.column(:year).items).to eq(expected)
      end

      it 'select eval with nils' do
        res = tab_a.select(
          :id,
          :salary,
          half_sal: 'salary / 2.0',
        )
        expected = ["10000.0", "10000.0", "32500.0", "42500.0", "", "10000.0", "2500.0", "2500.0"]
        expect(res[:half_sal].map(&:to_s)).to eq(expected)
      end
    end
  end
end
