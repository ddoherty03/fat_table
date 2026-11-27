# frozen_string_literal: true

module FatTable
  RSpec.describe Table do
    describe 'order_by' do
      let!(:tab) do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
          { a: '4', 'Two words' => '5', c: '6,412', d: 'orange' },
          { a: '7', 'Two words' => '8', c: '$1,888', d: 'apple' },
        ]
        Table.from_aoh(aoh)
      end

      it 'is able to sort its rows on one column' do
        expect(tab.order_by(:a).rows[0][:a]).to eq 4
      end

      it 'is able to sort its rows on multiple columns' do
        expect(tab.order_by(:d, :c).rows[0][:a]).to eq 7
      end

      it 'is able to reverse sort its rows on one column' do
        # tab = tab.order_by(:d!)
        expect(tab.order_by(:d!).rows[0][:d]).to eq 'orange'
        expect(tab.order_by(:d!).rows[2][:d]).to eq 'apple'
      end

      it 'sorts its rows on mixed forward and reverse columns' do
        tab2 = tab.order_by(:d!, :c)
        expect(tab2.rows[0][:d]).to eq 'orange'
        expect(tab2.rows[1][:d]).to eq 'apple'
        expect(tab2.rows[1][:c]).to eq 1888
        expect(tab2.rows[2][:d]).to eq 'apple'
      end
    end

    describe 'stable order_by' do
      let(:tab) do
        Table.from_aoh([
          { ref: 'first', category: 'b', rank: 2 },
          { ref: 'second', category: 'a', rank: nil },
          { ref: 'third', category: 'b', rank: 2 },
          { ref: 'fourth', category: 'a', rank: 1 },
          { ref: 'fifth', category: 'a', rank: nil },
          { ref: 'sixth', category: 'b', rank: 1 },
        ])
      end

      it 'preserves input order within tied keys without changing the source' do
        sorted = tab.order_by(:category)

        expect(sorted[:ref]).to eq(%w[second fourth fifth first third sixth])
        expect(sorted.boundaries).to eq([2, 5])
        expect(tab[:ref]).to eq(%w[first second third fourth fifth sixth])
      end

      it 'preserves input order within descending tied keys' do
        sorted = tab.order_by(:category!)

        expect(sorted[:ref]).to eq(%w[first third sixth second fourth fifth])
        expect(sorted.boundaries).to eq([2, 5])
      end

      it 'preserves nil and non-nil ties in both directions' do
        ascending = tab.order_by(:rank)
        descending = tab.order_by(:rank!)

        expect(ascending[:ref]).to eq(%w[second fifth fourth sixth first third])
        expect(descending[:ref]).to eq(%w[first third fourth sixth second fifth])
        expect(ascending.boundaries).to eq([1, 3, 5])
        expect(descending.boundaries).to eq([1, 3, 5])
      end

      it 'uses all requested keys before breaking ties for mixed directions' do
        sorted = tab.order_by(:category, :rank!)

        expect(sorted[:ref]).to eq(%w[fourth second fifth first third sixth])
        expect(sorted.boundaries).to eq([0, 2, 4, 5])
      end

      it 'preserves boolean and nil ties with descending secondary keys' do
        source = Table.from_aoh([
          { ref: 'first', active: true, rank: 1 },
          { ref: 'second', active: false, rank: 2 },
          { ref: 'third', active: nil, rank: 2 },
          { ref: 'fourth', active: true, rank: 1 },
          { ref: 'fifth', active: false, rank: 3 },
          { ref: 'sixth', active: nil, rank: 2 },
        ])
        ascending = source.order_by(:active, :rank!)
        descending = source.order_by(:active!, :rank)

        expect(ascending[:ref]).to eq(%w[third sixth fifth second first fourth])
        expect(ascending.boundaries).to eq([1, 2, 3, 5])
        expect(descending[:ref]).to eq(%w[first fourth second fifth third sixth])
        expect(descending.boundaries).to eq([1, 2, 3, 5])
      end

      it 'preserves tied expression results and their group boundaries' do
        sorted = tab.order_with('category!')

        expect(sorted[:ref]).to eq(%w[first third sixth second fourth fifth])
        expect(sorted[:sort_key]).to eq(%w[b b b a a a])
        expect(sorted.boundaries).to eq([2, 5])
      end

      it 'handles empty, single-row, and keyless sorts' do
        empty = tab.empty_dup.order_by(:category, :rank!)
        single = Table.from_aoh([{ ref: 'only', active: false }]).order_by(:active!)
        keyless = tab.order_by

        expect(empty.headers).to eq(tab.headers)
        expect(empty.rows).to be_empty
        expect(empty.boundaries).to be_empty
        expect(single.rows).to eq([{ ref: 'only', active: false }])
        expect(single.boundaries).to eq([0])
        expect(keyless.rows).to eq(tab.rows)
        expect(keyless.boundaries).to eq([5])
      end

      it 'keeps decimal ties stable and uses later date keys in mixed directions' do
        source = Table.from_aoh([
          { ref: 'first', amount: BigDecimal('2.0'), date: Date.new(2026, 1, 1) },
          { ref: 'second', amount: 2, date: Date.new(2026, 1, 2) },
          { ref: 'third', amount: 2, date: Date.new(2026, 1, 1) },
        ])
        sorted = source.order_by(:amount, :date!)

        expect(sorted[:ref]).to eq(%w[second first third])
        expect(sorted.boundaries).to eq([0, 2])
        expect(source[:ref]).to eq(%w[first second third])
      end
    end

    describe 'order_by with nils' do
      let!(:tab) do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
          { a: '4', 'Two words' => '5', c: '6,412', d: 'orange' },
          { a: '7', 'Two words' => '8', c: nil, d: 'apple' },
        ]
        Table.from_aoh(aoh)
      end

      it 'sorts its rows on one column' do
        tab2 = tab.order_by(:c)
        expect(tab2.rows[0][:c]).to be_nil
        expect(tab2.rows[1][:c]).to eq(3123)
        expect(tab2.rows[2][:c]).to eq(6412)
      end

      it 'sorts its rows on multiple columns' do
        tab2 = tab.order_by(:d, :c)
        expect(tab2.rows[0][:d]).to eq('apple')
        expect(tab2.rows[0][:c]).to be_nil
        expect(tab2.rows[1][:d]).to eq('apple')
        expect(tab2.rows[1][:c]).to eq(3123)
        expect(tab2.rows[2][:d]).to eq('orange')
        expect(tab2.rows[2][:c]).to eq(6412)
      end

      it 'reverse sorts its rows on one column' do
        tab2 = tab.order_by(:d!)
        expect(tab2.rows[0][:d]).to eq 'orange'
        expect(tab2.rows[1][:d]).to eq 'apple'
        expect(tab2.rows[2][:d]).to eq 'apple'
      end

      it 'sorts its rows on mixed forward and reverse columns' do
        tab2 = tab.order_by(:d!, :c)
        expect(tab2.rows[0][:d]).to eq 'orange'
        expect(tab2.rows[0][:c]).to eq(6412)
        expect(tab2.rows[1][:d]).to eq 'apple'
        expect(tab2.rows[1][:c]).to be_nil
        expect(tab2.rows[2][:d]).to eq 'apple'
        expect(tab2.rows[2][:c]).to eq 3123
      end
    end

    describe 'order_with' do
      let(:tab_a) do
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
      end
      let(:tab_g) do
        tab_g_str = <<~EOS
          | Ref  | Date             | Code |  Price | G10 | QP10 | Shares |   LP |    QP |   IPLP |   IPQP |
          |------+------------------+------+--------+-----+------+--------+------+-------+--------+--------|
          | T001 | [2016-11-01 Tue] | P    | 7.7000 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
          | T002 | [2016-11-01 Tue] | P    | 7.7500 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
          | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
          | T003 | [2016-11-01 Tue] | P    | 7.5000 | F   | T    |    800 |  112 |   688 | 0.2453 | 0.1924 |
          |------+------------------+------+--------+-----+------+--------+------+-------+--------+--------|
          | T004 | [2016-11-01 Tue] | S    | 7.5500 | T   | F    |   6811 |  966 |  5845 | 0.2453 | 0.1924 |
          | T005 | [2016-11-01 Tue] | S    | 7.5000 | F   | F    |   4000 |  572 |  3428 | 0.2453 | 0.1924 |
          | T006 | [2016-11-01 Tue] | S    | 7.6000 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
          | T006 | [2016-11-01 Tue] | S    | 7.6000 | F   | T    |   1000 |  143 |   857 | 0.2453 | 0.1924 |
          | T007 | [2016-11-01 Tue] | S    | 7.6500 | T   | F    |    200 |   28 |   172 | 0.2453 | 0.1924 |
          | T008 | [2016-11-01 Tue] | P    | 7.6500 | F   | F    |   2771 |  393 |  2378 | 0.2453 | 0.1924 |
          | T009 | [2016-11-01 Tue] | P    | 7.6000 | F   | F    |   9550 | 1363 |  8187 | 0.2453 | 0.1924 |
          |------+------------------+------+--------+-----+------+--------+------+-------+--------+--------|
          | T010 | [2016-11-01 Tue] | P    | 7.5500 | F   | T    |   3175 |  451 |  2724 | 0.2453 | 0.1924 |
          | T011 | [2016-11-02 Wed] | P    | 7.4250 | T   | F    |    100 |   14 |    86 | 0.2453 | 0.1924 |
          | T012 | [2016-11-02 Wed] | P    | 7.5500 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
          | T012 | [2016-11-02 Wed] | P    | 7.5500 | F   | F    |   4700 |  677 |  4023 | 0.2453 | 0.1924 |
          | T013 | [2016-11-02 Wed] | P    | 7.3500 | T   | T    |  53100 | 7656 | 45444 | 0.2453 | 0.1924 |
          |------+------------------+------+--------+-----+------+--------+------+-------+--------+--------|
          | T014 | [2016-11-02 Wed] | P    | 7.4500 | F   | T    |   5847 |  835 |  5012 | 0.2453 | 0.1924 |
          | T015 | [2016-11-02 Wed] | P    | 7.7500 | F   | F    |    500 |   72 |   428 | 0.2453 | 0.1924 |
          | T016 | [2016-11-02 Wed] | P    | 8.2500 | T   | T    |    100 |   14 |    86 | 0.2453 | 0.1924 |
        EOS
        FatTable.from_org_string(tab_g_str)
      end

      it 'orders by expression' do
        tab_b = tab_a.order_with('join_date.year')
        expect(tab_b[:sort_key][0]).to be_nil
        expect(tab_b[:sort_key][1]).to eq(2001)
        expect(tab_b[:sort_key][2]).to eq(2005)
        expect(tab_b[:sort_key][3]).to eq(2005)
        expect(tab_b[:sort_key][4]).to eq(2005)
        expect(tab_b[:sort_key][5]).to eq(2007)
        expect(tab_b[:sort_key][6]).to eq(2007)
        expect(tab_b[:sort_key][7]).to eq(2007)
        expect(tab_b.number_of_groups).to eq(4)
      end

      it 'reverse orders by expression' do
        tab_b = tab_a.order_with('join_date.year!')
        expect(tab_b[:sort_key][7]).to be_nil
        expect(tab_b[:sort_key][6]).to eq(2001)
        expect(tab_b[:sort_key][5]).to eq(2005)
        expect(tab_b[:sort_key][4]).to eq(2005)
        expect(tab_b[:sort_key][3]).to eq(2005)
        expect(tab_b[:sort_key][2]).to eq(2007)
        expect(tab_b[:sort_key][1]).to eq(2007)
        expect(tab_b[:sort_key][0]).to eq(2007)
        expect(tab_b.number_of_groups).to eq(4)
      end

      it 'orders by boolean expression' do
        tab_b = tab_g.order_with('g10 && qp10')
        expect(tab_b.number_of_groups).to eq(2)
      end
    end
  end
end
