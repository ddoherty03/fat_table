module FatTable
  describe Evaluator, :aggregate_failures do
    describe 'instance variables' do
      let(:ev) do
        described_class.new(ivars: { group: 0, row: 1, junk: Date.parse('2017-09-22') },
                            before: '@group += 1; @row += 2',
                            after:  '@group *= 2; @row *= 3')
      end

      it 'gets instance variables' do
        expect(ev.evaluate('@group')).to eq(0)
        expect(ev.evaluate('@row')).to eq(1)
        expect(ev.evaluate('@junk.day')).to eq(22)
      end

      it 'sets instance variables' do
        ev.update_ivars(junk: 'hello', row: 55, group: 4)
        expect(ev.evaluate('@group')).to eq(4)
        expect(ev.evaluate('@row')).to eq(55)
        expect(ev.evaluate('@junk')).to eq('hello')
      end

      it 'evaluates expressions with instance variables' do
        expect(ev.evaluate('(@group + @row + 1) * @junk.month')).to eq(18)
      end
    end

    describe 'before hook' do
      let(:ev) do
        described_class.new(ivars: { group: 0, row: 1, junk: Date.parse('2017-09-22') },
                            before: '@group += 1; @row += 2')
      end

      let(:locs) { { a: 1, b: 3, c: 5 } }

      it 'updates instance variables on each before hook eval' do
        expect(ev.evaluate('@group * (a + b)', locals: locs)).to eq(0)
        expect(ev.evaluate('@row * (a + b)', locals: locs)).to eq(4)
        ev.eval_before_hook
        expect(ev.evaluate('@group * (a + b)', locals: locs)).to eq(4)
        expect(ev.evaluate('@row * (a + b)', locals: locs)).to eq(12)
        ev.eval_before_hook
        expect(ev.evaluate('@group * (a + b)', locals: locs)).to eq(8)
        expect(ev.evaluate('@row * (a + b)', locals: locs)).to eq(20)
      end
    end

    describe 'after hook' do
      let(:ev) do
        described_class.new(ivars: { group: 1, row: 1, junk: Date.parse('2017-09-22') },
                            after:  '@group *= 2; @row *= 3; @junk = @junk + 1.year')
      end

      let(:locs) { { a: 1, b: 3, c: 5 } }

      it 'updates instance variables on each after hook eval' do
        ev.eval_after_hook
        expect(ev.evaluate('@group + c', locals: locs)).to eq(7)
        expect(ev.evaluate('@row')).to eq(3)
        expect(ev.evaluate('@junk.year')).to eq(2018)
      end
    end

    describe 'evaluate' do
      let(:ev) { described_class.new }
      let(:locs) { { a: 1, b: 3, c: 5 } }

      it 'evaluates with locals only' do
        expect(ev.evaluate('b**2 + 16 == c**2', locals: locs)).to be_truthy
        expect(ev.evaluate('a + b + c', locals: locs)).to eq(9)
      end
    end
  end
end
