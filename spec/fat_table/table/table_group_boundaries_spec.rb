module FatTable
  RSpec.describe Table do
    describe 'group boundaries' do
      before :all do
        @tab_a = Table.from_aoh(
          [
            { id: 1, name: 'Paul', age: 32, address: 'California',
              salary: 20000, join_date: '2001-07-13', },
            { id: 3, name: 'Teddy', age: 23, address: 'Norway',
              salary: 20000, },
            { id: 4, name: 'Mark', age: 25, address: 'Rich-Mond',
              salary: 65000, join_date: '2007-12-13', },
            { id: 5, name: 'David', age: 27, address: 'Texas',
              salary: 85000, join_date: '2007-12-13', },
            { id: 2, name: 'Allen', age: 25, address: 'Texas',
              salary: nil, join_date: '2007-12-13', },
            { id: 8, name: 'Paul', age: 24, address: 'Houston',
              salary: 20000, join_date: '2005-07-13', },
            { id: 9, name: 'James', age: 44, address: 'Norway',
              salary: 5000, join_date: '2005-07-13', },
            { id: 10, name: 'James', age: 45, address: 'Texas',
              salary: 5000, join_date: '2005-07-13', },
          ]
        )
        # Union compatible with tab_a
        @tab_a1 = Table.from_aoh(
          [
            { id: 21, name: 'Paula', age: 23, address: 'Kansas',
              salary: 20000, join_date: '2001-07-13', },
            { id: 23, name: 'Jenny', age: 32, address: 'Missouri',
              salary: 20000, },
            { id: 24, name: 'Forrest', age: 52, address: 'Richmond',
              salary: 65000, join_date: '2007-12-13', },
            { id: 25, name: 'Syrano', age: 72, address: 'Nebraska',
              salary: 85000, join_date: '2007-12-13', },
            # Next four are the same as row as in @tab_a
            { id: 2, name: 'Allen', age: 25, address: 'Texas',
              salary: nil, join_date: '2007-12-13', },
            { id: 8, name: 'Paul', age: 24, address: 'Houston',
              salary: 20000, join_date: '2005-07-13', },
            { id: 9, name: 'James', age: 44, address: 'Norway',
              salary: 5000, join_date: '2005-07-13', },
            { id: 10, name: 'James', age: 45, address: 'Texas',
              salary: 5000, join_date: '2005-07-13', },
            { id: 22, name: 'Paula', age: 52, address: 'Iowa',
              salary: nil, join_date: '2007-12-13', },
            { id: 28, name: 'Paula', age: 42, address: 'Oklahoma',
              salary: 20000, join_date: '2005-07-13', },
            { id: 29, name: 'Patrick', age: 44, address: 'Lindsbourg',
              salary: 5000, join_date: '2005-07-13', },
            { id: 30, name: 'James', age: 54, address: 'Ottawa',
              salary: 5000, join_date: '2005-07-13', },
          ]
        )
        @tab_b = Table.from_aoh(
          [
            { id: 1, dept: 'IT Billing', emp_id: 1 },
            { id: 2, dept: 'Engineering', emp_id: 2 },
            { id: 3, dept: 'Finance', emp_id: 7 },
          ]
        )
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
        @aoh = [
          {
            id: 1, name: 'Paul', age: 32, address: 'California', salary: 20000,
            join_date: '2001-07-13',
          },
          nil,
          { id: 3, name: 'Teddy', age: 23, address: 'Norway', salary: 20000 },
          {
            id: 4, name: 'Mark', age: 25, address: 'Rich-Mond', salary: 65000,
            join_date: '2007-12-13',
          },
          {
            id: 5, name: 'David', age: 27, address: 'Texas', salary: 85000,
            join_date: '2007-12-13',
          },
          nil,
          {
            id: 2, name: 'Allen', age: 25, address: 'Texas', salary: nil,
            join_date: '2007-12-13',
          },
          {
            id: 8, name: 'Paul', age: 24, address: 'Houston', salary: 20000,
            join_date: '2005-07-13',
          },
          {
            id: 9, name: 'James', age: 44, address: 'Norway', salary: 5000,
            join_date: '2005-07-13',
          },
          nil,
          {
            id: 10, name: 'James', age: 45, address: 'Texas', salary: 5000,
            join_date: '2005-07-13',
          },
        ]
      end

      it 'an empty table should have no groups' do
        expect(Table.new.groups.size).to eq(0)
      end

      it 'default group boundaries of whole table' do
        expect(@tab_a.groups.size).to eq(1)
      end

      it 'add group boundaries on reading from aoa' do
        tab = Table.from_aoa(@aoa, hlines: true)
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(7)
        expect(tab.groups[3].size).to eq(1)
      end

      it 'add group boundaries explicity' do
        # As in prior example
        tab = Table.from_aoa(@aoa, hlines: true)
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(7)
        expect(tab.groups[3].size).to eq(1)
        # Now add a boundary after row 8, spliting group 2 at that point.
        tab.add_boundary(8)
        expect(tab.groups.size).to eq(5)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(5)
        expect(tab.groups[3].size).to eq(2)
        expect(tab.groups[4].size).to eq(1)
      end

      it 'add group boundaries on reading from aoh' do
        tab = Table.from_aoh(@aoh, hlines: true)
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(3)
        expect(tab.groups[3].size).to eq(1)
      end

      it 'add group boundaries on order_by' do
        tab = @tab_a.order_by(:name)
        # Now the table is ordered by name, and the names are: Allen, David,
        # James, James, Mark, Paul, Paul, Teddy. So there are groups of size 1,
        # 1, 2, 1, 2, and 1.  Six groups in all.
        expect(tab.groups.size).to eq(6)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(1)
        expect(tab.groups[2].size).to eq(2)
        tab.groups[2].each do |row|
          expect(row[:name]).to eq('James')
        end
        expect(tab.groups[3].size).to eq(1)
        expect(tab.groups[4].size).to eq(2)
        tab.groups[4].each do |row|
          expect(row[:name]).to eq('Paul')
        end
        expect(tab.groups[5].size).to eq(1)
      end

      it 'add group boundaries on union_all' do
        tab = @tab_a.union_all(@tab_a1)
        expect(tab.size).to eq(20)
        expect(tab.groups.size).to eq(2)
        expect(tab.groups[0].size).to eq(8)
        expect(tab.groups[1].size).to eq(12)
      end

      it 'inherit group boundaries on union_all' do
        tab1 = @tab_a.order_by(:name)
        tab2 = @tab_a1.order_by(:name)
        tab = tab1.union_all(tab2)
        expect(tab.size).to eq(20)
        expect(tab.groups.size).to eq(tab1.groups.size + tab2.groups.size)
        tab.groups.each do |grp|
          names = grp.map { |r| r[:name] }
          expect(names.uniq.size).to eq(1)
        end
      end

      it 'inherit group boundaries on select' do
        tab = @tab_a.order_by(:name).select(:name, :age, :join_date)
        # Now the table is ordered by name, and the names are: Allen, David,
        # James, James, Mark, Paul, Paul, Teddy. So there are groups of size 1,
        # 1, 2, 1, 2, and 1.  Six groups in all.
        expect(tab.groups.size).to eq(6)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(1)
        expect(tab.groups[2].size).to eq(2)
        tab.groups[2].each do |row|
          expect(row[:name]).to eq('James')
        end
        expect(tab.groups[3].size).to eq(1)
        expect(tab.groups[4].size).to eq(2)
        tab.groups[4].each do |row|
          expect(row[:name]).to eq('Paul')
        end
        expect(tab.groups[5].size).to eq(1)
      end
    end
  end
end
