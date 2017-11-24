require 'spec_helper'

module FatTable
  describe Table do
    describe 'join' do
      # These tests are taken from https://www.tutorialspoint.com/postgresql/postgresql_using_joins.htm
      before :all do
        @tab_a = Table.from_aoh(
          [
            { id: 1, name: 'Paul', age: 32, address: 'California',
              salary: 20000, join_date: '2001-07-13' },
            { id: 3, name: 'Teddy', age: 23, address: 'Norway',
              salary: 20000 },
            { id: 4, name: 'Mark', age: 25, address: 'Rich-Mond',
              salary: 65000, join_date: '2007-12-13' },
            { id: 5, name: 'David', age: 27, address: 'Texas',
              salary: 85000, join_date: '2007-12-13' },
            { id: 2, name: 'Allen', age: 25, address: 'Texas',
              salary: nil, join_date: '2007-12-13' },
            { id: 8, name: 'Paul', age: 24, address: 'Houston',
              salary: 20000, join_date: '2005-07-13' },
            { id: 9, name: 'James', age: 44, address: 'Norway',
              salary: 5000, join_date: '2005-07-13' },
            { id: 10, name: 'James', age: 45, address: 'Texas',
              salary: 5000, join_date: '2005-07-13' }
          ]
        )
        @tab_b = Table.from_aoh(
          [
            { id: 1, dept: 'IT Billing', emp_id: 1 },
            { id: 2, dept: 'Engineering', emp_id: 2 },
            { id: 3, dept: 'Finance', emp_id: 7 }
          ]
        )
      end

      it 'should be able to do an inner join' do
        join_tab = @tab_a.join(@tab_b, :id_a, :emp_id_b)
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(2)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab.headers).to eq(%i[id name age address salary
                                          join_date id_b dept])
      end

      it 'should be able to do an inner join on a string exp' do
        join_tab = @tab_a.join(@tab_b, 'id_a == emp_id_b')
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(2)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab.headers).to eq(%i[id name age address salary
                                          join_date id_b dept emp_id])
      end

      it 'should be able to do a left join' do
        join_tab = @tab_a.left_join(@tab_b, :id_a, :emp_id_b)
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(8)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab[:name]).to include('Teddy')
        expect(join_tab[:name]).to include('Mark')
        expect(join_tab[:name]).to include('David')
        expect(join_tab[:name]).to include('James')
        expect(join_tab.headers).to eq(%i[id name age address salary join_date
                                          id_b dept emp_id])
      end

      it 'should be able to do a right join' do
        join_tab = @tab_a.right_join(@tab_b, :id_a, :emp_id_b)
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(3)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab[:dept]).to include('IT Billing')
        expect(join_tab[:dept]).to include('Engineering')
        expect(join_tab[:dept]).to include('Finance')
        expect(join_tab.headers).to eq(%i[id name age address salary
                                          join_date id_b dept emp_id])
      end

      it 'should be able to do a full join' do
        join_tab = @tab_a.full_join(@tab_b, :id_a, :emp_id_b)
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(9)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab[:name]).to include('Teddy')
        expect(join_tab[:name]).to include('Mark')
        expect(join_tab[:name]).to include('David')
        expect(join_tab[:name]).to include('James')
        expect(join_tab[:dept]).to include('IT Billing')
        expect(join_tab[:dept]).to include('Engineering')
        expect(join_tab[:dept]).to include('Finance')
        expect(join_tab.headers).to eq(%i[id name age address salary
                                          join_date id_b dept emp_id])
      end

      it 'should be able to do a cross join' do
        join_tab = @tab_a.cross_join(@tab_b)
        expect(join_tab.class).to eq Table
        expect(join_tab.size).to eq(24)
        expect(join_tab[:name]).to include('Paul')
        expect(join_tab[:name]).to include('Allen')
        expect(join_tab[:name]).to include('Teddy')
        expect(join_tab[:name]).to include('Mark')
        expect(join_tab[:name]).to include('David')
        expect(join_tab[:name]).to include('James')
        expect(join_tab[:dept]).to include('IT Billing')
        expect(join_tab[:dept]).to include('Engineering')
        expect(join_tab[:dept]).to include('Finance')
        expect(join_tab.headers).to eq(%i[id name age address salary
                                          join_date id_b dept emp_id])
      end
    end
  end
end
