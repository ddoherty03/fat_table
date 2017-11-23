module FatTable
  describe Table do
    describe 'accessing' do
      before :all do
        @tab =
          Table.from_aoh(
            [{ a: '1', 'Two words' => '2', c: '3,123', d: 'apple' },
             { a: '4', 'Two words' => '5', c: '6,412', d: 'orange' },
             { a: '7', 'Two words' => '8', c: '$9,888', d: 'pear' }]
          )
      end

      it 'should act as an Enumerable' do
        @tab.each do |r|
          expect(r.class).to eq(Hash)
        end
      end

      it 'should be able to index by column head' do
        expect(@tab[:a]).to eq([1, 4, 7])
        expect(@tab[:d]).to eq(%w[apple orange pear])
        expect { @tab[:r] }.to raise_error(/not in table/)
      end

      it 'should be able to index by row number' do
        expect(@tab[0]).to eq(a: 1, two_words: 2, c: 3123, d: 'apple')
        expect(@tab[2]).to eq(a: 7, two_words: 8, c: 9888, d: 'pear')
        expect(@tab[-1]).to eq(a: 7, two_words: 8, c: 9888, d: 'pear')
        expect { @tab[4] }.to raise_error(/out of range/)
      end

      it 'should be able to report if column exists' do
        expect(@tab.column?(:a)).to be true
        expect(@tab.column?('a')).to be true
        expect(@tab.column?('A')).to be true
        expect(@tab.column?(:x)).to be false
      end

      it 'should be able to report column types' do
        typs = @tab.types
        expect(typs.class).to eq(Hash)
        expect(typs[:a]).to eq('Numeric')
        expect(typs[:two_words]).to eq('Numeric')
        expect(typs[:c]).to eq('Numeric')
        expect(typs[:d]).to eq('String')
      end

      it 'should be able to report its headers' do
        expect(@tab.headers).to eq [:a, :two_words, :c, :d]
      end

      it 'should be able to report the table size' do
        expect(@tab.size).to eq(3)
        expect(Table.new.size).to eq(0)
      end

      it 'should be able to report the table width' do
        expect(@tab.width).to eq(4)
        expect(Table.new.size).to eq(0)
      end

      it 'should be able to determine if table is empty' do
        expect(Table.new.empty?).to be true
        expect(@tab.empty?).to be false
      end
    end
  end
end
