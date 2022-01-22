module FatTable
  RSpec.describe Table do
    describe 'degroup!' do
      before :all do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
          { a: '5', 'Two words' => '20', c: '3,123', d: 'kiwi' },
          { a: '4', 'Two words' => '5', c: '6,412', d: 'orange' },
          { a: '7', 'Two words' => '8', c: '$1,888', d: 'apple' },
          { a: 7, 'Two words' => '8', c: 1_889, d: 'apple' },
        ]
        @tab = Table.from_aoh(aoh).order_by(:a)
      end

      it 'remove groups after sort on one column' do
        tab = @tab.order_by(:a)
        expect(tab.groups.size).to eq(3)
        tab = tab.degroup!
        expect(tab.groups.size).to eq(1)
      end

      it 'should be able to remove groups after sort on two columns' do
        tab = @tab.order_by(:a, :c)
        expect(tab.groups.size).to eq(4)
        tab = tab.degroup!
        expect(tab.groups.size).to eq(1)
      end
    end
  end
end
