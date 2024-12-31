module FatTable
  RSpec.describe Table do
    describe 'degroup!' do
      let(:tab) do
        aoh = [
          { a: '5', 'Two words' => '20', c: '3,123', d: 'apple' },
          { a: '5', 'Two words' => '20', c: '3,123', d: 'kiwi' },
          { a: '4', 'Two words' => '5', c: '6,412', d: 'orange' },
          { a: '7', 'Two words' => '8', c: '$1,888', d: 'apple' },
          { a: 7, 'Two words' => '8', c: 1_889, d: 'apple' },
        ]
        Table.from_aoh(aoh).order_by(:a)
      end

      it 'remove groups after sort on one column' do
        tab_by_a = tab.order_by(:a)
        expect(tab_by_a.groups.size).to eq(3)
        tab_degrouped = tab.degroup!
        expect(tab_degrouped.groups.size).to eq(1)
      end

      it 'is able to remove groups after sort on two columns' do
        tab_by_ac = tab.order_by(:a, :c)
        expect(tab_by_ac.groups.size).to eq(4)
        tab_degrouped = tab.degroup!
        expect(tab_degrouped.groups.size).to eq(1)
      end
    end
  end
end
