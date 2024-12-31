module FatTable
  RSpec.describe Table do
    describe 'output' do
      # These tests are taken from https://www.tutorialspoint.com/postgresql/postgresql_using_joins.htm
      let(:tab) do
        Table.from_aoh(
          [
            {
              id: 1,
              name: 'Paul',
              age: 32,
              address: 'California',
              salary: 20000,
              join_date: '2001-07-13',
            },
            { id: 3, name: 'Teddy', age: 23, address: 'Norway', salary: 20000, },
            {
              id: 4,
              name: 'Mark',
              age: 25,
              address: 'Rich-Mond',
              salary: 65000,
              join_date: '2007-12-13',
            },
            {
              id: 5,
              name: 'David',
              age: 27,
              address: 'Texas',
              salary: 85000,
              join_date: '2007-12-13',
            },
            {
              id: 2,
              name: 'Allen',
              age: 25,
              address: 'Texas',
              salary: nil,
              join_date: '2007-12-13',
            },
            {
              id: 8,
              name: 'Paul',
              age: 24,
              address: 'Houston',
              salary: 20000,
              join_date: '2005-07-13',
            },
            {
              id: 9,
              name: 'James',
              age: 44,
              address: 'Norway',
              salary: 5000,
              join_date: '2005-07-13',
            },
            {
              id: 10,
              name: 'James',
              age: 45,
              address: 'Texas',
              salary: 5000,
              join_date: '2005-07-13',
            },
          ],
        )
      end

      it 'is able to output to aoa' do
        out = tab.to_aoa
        expect(out.class).to eq(Array)
        expect(out.first.class).to eq(Array)
      end

      it 'is able to output to aoh' do
        out = tab.to_aoh
        expect(out.class).to eq(Array)
        expect(out.first.class).to eq(Hash)
      end

      it 'is able to output to text' do
        out = tab.to_text
        expect(out.class).to eq(String)
      end
    end
  end
end
