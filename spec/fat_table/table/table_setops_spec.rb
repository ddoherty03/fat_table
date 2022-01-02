module FatTable
  describe Table do
    before :all do
      aoh = [
        { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
        { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
        { a: '4', 'Two words' => '5', c: 6412, d: 'orange' },
        { a: '7', 'Two words' => '8', c: '$1,888', d: 'apple' },
      ]
      @tab1 = Table.from_aoh(aoh)
      aoh2 = [
        { t: '8', 'Two words' => '65', s: '5,143', u: 'kiwi' },
        { t: '4', 'Two words' => '5', s: 6412, u: 'orange' },
        nil,
        { t: '87', 'Two words' => '12', s: 412, u: 'banana' },
        { t: '4', 'Two words' => '5', s: 6412, u: 'orange' },
        { t: '13', 'Two words' => '11', s: '$1,821', u: 'grape' },
      ]
      @tab2 = Table.from_aoh(aoh2, hlines: true)
      # This table is not set compatible with the first two by reason of number
      # of columns.
      aoh3 = [
        { a: '5', 'Two words' => '20', c: '3,123' },
        { a: '4', 'Two words' => '5', c: 6412 },
        { a: '4', 'Two words' => '5', c: 6412 },
        { a: '7', 'Two words' => '8', c: '$1,888' },
      ]
      @tab3 = Table.from_aoh(aoh3)
      # This table is not set compatible with the first two by reason of column
      # type
      aoh4 = [
        { t: '8',  'Two worlds' => '65', s: '2016-01-17',   u: 'kiwi' },
        { t: '87', 'Two worlds' => '12', s: Date.today,     u: 'banana' },
        { t: '13', 'Two worlds' => '11', s: '[2015-05-21]', u: 'grape' },
      ]
      @tab4 = Table.from_aoh(aoh4)
    end

    describe 'union' do
      it 'should be able to union with a compatible table' do
        utab = @tab1.union(@tab2)
        expect(utab.rows.size).to eq(6)
        expect(utab.groups.size).to eq(1)
      end

      it 'should be able to union_all with a compatible table' do
        utab = @tab1.union_all(@tab2)
        expect(utab.rows.size).to eq(9)
        expect(utab.groups.size).to eq(3)
      end

      it 'should throw an exception for union with different sized tables' do
        expect {
          @tab1.union(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'should throw an exception for union with different types' do
        expect {
          @tab1.union(@tab4)
        }.to raise_error(/different column types/)
      end

      it 'should throw exception for union_all with different sized tables' do
        expect {
          @tab1.union_all(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'should throw an exception for union_all with different types' do
        expect {
          @tab1.union_all(@tab4)
        }.to raise_error(/different column types/)
      end
    end

    describe 'intersect' do
      it 'should return the intersect of two tables' do
        itab = @tab1.intersect(@tab2)
        expect(itab.size).to eq(1)
        expect(itab.groups.size).to eq(1)
      end

      it 'should return the intersect_all of two tables' do
        # Notice that the order of operands matters.
        itab = @tab1.intersect_all(@tab2)
        expect(itab.size).to eq(1)
        expect(itab.groups.size).to eq(1)
        itab = @tab2.intersect_all(@tab1)
        expect(itab.size).to eq(2)
        expect(itab.groups.size).to eq(1)
      end

      it 'throw exception for intersect with different sized tables' do
        expect {
          @tab1.intersect(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'throw an exception for intersect with different types' do
        expect {
          @tab1.intersect(@tab4)
        }.to raise_error(/different column types/)
      end

      it 'throw exception for intersect_all with different size tables' do
        expect {
          @tab1.intersect_all(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'throw an exception for intersect_all with different types' do
        expect {
          @tab1.intersect_all(@tab4)
        }.to raise_error(/different column types/)
      end
    end

    describe 'except' do
      it 'should return the except of two tables' do
        itab = @tab1.except(@tab2)
        expect(itab.size).to eq(2)
        expect(itab.groups.size).to eq(1)
      end

      it 'should return the except_all of two tables' do
        # Notice that the order of operands matters.
        itab = @tab1.except_all(@tab2)
        expect(itab.size).to eq(3)
        expect(itab.groups.size).to eq(1)
        itab = @tab2.except_all(@tab1)
        expect(itab.size).to eq(3)
        expect(itab.groups.size).to eq(1)
      end

      it 'should throw exception for except with different sized tables' do
        expect {
          @tab1.except(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'should throw an exception for except with different types' do
        expect {
          @tab1.except(@tab4)
        }.to raise_error(/different column types/)
      end

      it 'should throw exception for except_all with different sized tables' do
        expect {
          @tab1.except_all(@tab3)
        }.to raise_error(/different number of columns/)
      end

      it 'should throw an exception for except_all with different types' do
        expect {
          @tab1.except_all(@tab4)
        }.to raise_error(/different column types/)
      end
    end
  end
end
