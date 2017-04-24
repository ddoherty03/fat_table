require 'spec_helper'

module FatTable
  describe Table do
    describe 'union' do
      it 'should be able to union with a compatible table' do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
          { a: '4', 'Two words' => '5', c: 6412, d: 'orange' },
          { a: '7', 'Two words' => '8', c: '$1,888', d: 'apple' }
        ]
        tab1 = Table.from_aoh(aoh)
        aoh2 = [
          { t: '8', 'Two worlds' => '65', s: '5,143', u: 'kiwi' },
          { t: '87', 'Two worlds' => '12', s: 412, u: 'banana' },
          { t: '13', 'Two worlds' => '11', s: '$1,821', u: 'grape' }
        ]
        tab2 = Table.from_aoh(aoh2)
        utab = tab1.union(tab2)
        expect(utab.rows.size).to eq(6)
      end

      it 'should throw an exception for union with different sized tables' do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123' },
          { a: '4', 'Two words' => '5', c: 6412 },
          { a: '7', 'Two words' => '8', c: '$1,888' }
        ]
        tab1 = Table.from_aoh(aoh)
        aoh2 = [
          { t: '8', 'Two worlds' => '65', s: '5,143', u: 'kiwi' },
          { t: '87', 'Two worlds' => '12', s: 412, u: 'banana' },
          { t: '13', 'Two worlds' => '11', s: '$1,821', u: 'grape' }
        ]
        tab2 = Table.from_aoh(aoh2)
        expect {
          tab1.union(tab2)
        }.to raise_error(/different number of columns/)
      end

      it 'should throw an exception for union with different types' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5143',  c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1821', c: '$1888' }
        ]
        tab1 = Table.from_aoh(aoh)
        aoh2 = [
          { t: '8',  'Two worlds' => '65', s: '2016-01-17',   u: 'kiwi' },
          { t: '87', 'Two worlds' => '12', s: Date.today,     u: 'banana' },
          { t: '13', 'Two worlds' => '11', s: '[2015-05-21]', u: 'grape' }
        ]
        tab2 = Table.from_aoh(aoh2)
        expect {
          tab1.union(tab2)
        }.to raise_error(/different column types/)
      end
    end
  end
end
