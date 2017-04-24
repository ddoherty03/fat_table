require 'spec_helper'

module FatTable
  describe Table do
    describe 'select' do
      it 'should be able to select by column names' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5143',  c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1821', c: '$1888' }
        ]
        tab1 = Table.from_aoh(aoh)
        tab2 = tab1.select(:s, :a, :c)
        expect(tab2.headers).to eq [:s, :a, :c]
      end

      it 'should be able to select by column names renaming columns' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5143',  c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1821', c: '$1888' }
        ]
        tab1 = Table.from_aoh(aoh)
        tab2 = tab1.select(former_s: :s, new_a: :a, renew_c: :c)
        expect(tab2.headers).to eq [:former_s, :new_a, :renew_c]
      end

      it 'should be able to select new columns computed from prior' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5143',  c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1821', c: '$1888' }
        ]
        tab1 = Table.from_aoh(aoh)
        tab2 = tab1.select(:two_words, row: '@row', s_squared: 's * s',
                           arb: 's_squared / (a + c).to_d')
        expect(tab2.headers).to eq [:two_words, :row, :s_squared, :arb]
      end

      it 'should be able to use old value of current column to compute new value' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5_143', c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1821', c: '$1_888' }
        ]
        tab1 = Table.from_aoh(aoh)
        tab2 = tab1.select(:two_words, s: 's * s', nc: 'c + c', c: 'nc+nc')
        expect(tab2.headers).to eq [:two_words, :s, :nc, :c]
        expect(tab2[:s]).to eq([26450449, 169744, 3316041])
        expect(tab2[:c]).to eq([12492, 25648, 7552])
      end

      it 'should have access to @row and @group vars in evaluating' do
        aoh = [
          { a: '5', 'Two words' => '20', s: '5_143', c: '3123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 6412 },
          { a: '7', 'Two words' => '8',  s: '$1721', c: '$1_888' },
          { a: '5', 'Two words' => '20', s: '4_143', c: '4123' },
          { a: '4', 'Two words' => '5',  s: 512,     c: 5412 },
          { a: '7', 'Two words' => '8',  s: '$1621', c: '$2_888' },
          { a: '5', 'Two words' => '20', s: '3_143', c: '5123' },
          { a: '4', 'Two words' => '5',  s: 412,     c: 4412 },
          { a: '7', 'Two words' => '8',  s: '$1521', c: '$3_888' }
        ]
        tab = Table.from_aoh(aoh).order_by(:a, :two_words)
        tab2 = tab.select(:a, :two_words, number: '@row', group: '@group')
        expect(tab2.headers).to eq [:a, :two_words, :number, :group]
        expect(tab2[:number]).to eq([1, 2, 3, 4, 5, 6, 7, 8, 9])
        expect(tab2[:group]).to eq([1, 1, 1, 2, 2, 2, 3, 3, 3])
      end
    end
  end
end
