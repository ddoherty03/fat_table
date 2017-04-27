require 'spec_helper'

module FatTable
  describe Column do
    before :all do
      @bool_items = [ nil, 't', 'true', 'False', 'nO', 'y', nil, 'Y', 'yEs', 'yippers' ]
    end

    describe 'initialization of boolean' do
      it 'should initialize a good boolean column without trailing nils' do
        items = [nil, 't', 'true', 'False', 'nO', 'y', 'Y', 'yEs']
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('Boolean')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(true)
        expect(col[2]).to eq(true)
        expect(col[3]).to eq(false)
        expect(col[4]).to eq(false)
        expect(col[5]).to eq(true)
        expect(col[6]).to eq(true)
        expect(col[7]).to eq(true)
        expect(col.size).to eq(8)
      end

      it 'should initialize a good boolean column with trailing nils' do
        items = [nil, 't', 'true', 'False', 'nO', 'y', nil, 'Y', 'yEs', '']
        col = Column.new(header: 'junk', items: items)
        expect(col.type).to eq('Boolean')
        expect(col.size).to eq(10)
      end

      it 'should raise an error initializing a boolean column with trailing numeric' do
        items = [nil, 't', 'true', 'False', 'nO', '32.8', 'y', nil, 'Y', 'yEs']
        expect {
          Column.new(header: 'junk', items: items)
        }.to raise_error(/already typed as Boolean/)
      end
    end

    describe 'initialization of datetime' do
      it 'should initialize a good datetime column without trailing nils' do
        items = [nil, nil, '2018-01-21', Date.parse('1957/9/22'), '1957/9/22',
                 '1956-03-16 08:21:13', '[2017-04-22 Sat]', '<2017-04-23>']
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('DateTime')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq(Date.new(2018, 1, 21))
        expect(col[3]).to eq(Date.new(1957, 9, 22))
        expect(col[4]).to eq(Date.new(1957, 9, 22))
        expect(col[5]).to eq(DateTime.new(1956, 3, 16, 8, 21, 13))
        expect(col[6]).to eq(Date.new(2017, 4, 22))
        expect(col.size).to eq(8)
      end

      it 'should initialize a good boolean column with trailing nils' do
        items = [nil, nil, '2018-01-21', '', nil, Date.parse('1957/9/22'),
                 '1957/9/22', '1956-03-16 08:21:13']
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('DateTime')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq(Date.new(2018, 1, 21))
        expect(col[2].class).to eq(Date)
        expect(col[3]).to eq(nil)
        expect(col[4]).to eq(nil)
        expect(col[5]).to eq(Date.new(1957, 9, 22))
        expect(col[5].class).to eq(Date)
        expect(col[6]).to eq(Date.new(1957, 9, 22))
        expect(col[6].class).to eq(Date)
        expect(col[7]).to eq(DateTime.new(1956, 3, 16, 8, 21, 13))
        expect(col[7].class).to eq(DateTime)
        expect(col.size).to eq(8)
      end

      it 'should raise an error for a datetime column with trailing numeric' do
        items = [nil, nil, '2018-01-21', '36.8', nil, Date.parse('1957/9/22'),
                 '1957/9/22', '1956-03-16 08:21:13']
        expect {
          Column.new(header: 'junk', items: items)
        }.to raise_error(/already typed as DateTime/)
      end
    end

    describe 'initialization of numeric' do
      it 'should initialize a good numeric column without trailing nils' do
        items = [nil, nil, '$2_018', 3.14159, '1,957/9', '2:3', 64646464646]
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('Numeric')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq(2018)
        expect(col[3]).to eq(3.14159)
        expect(col[4]).to eq(Rational(1957, 9))
        expect(col[5]).to eq(Rational(2, 3))
        expect(col[6]).to eq(64646464646)
        expect(col.size).to eq(7)
      end

      it 'should initialize a good numeric column with trailing nils' do
        items = [nil, nil, '2018', 3.14159, '1957/9', nil, '', '2:3', 64646464646]
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('Numeric')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq(2018)
        expect(col[3]).to eq(3.14159)
        expect(col[4]).to eq(Rational(1957, 9))
        expect(col[5]).to eq(nil)
        expect(col[6]).to eq(nil)
        expect(col[7]).to eq(Rational(2, 3))
        expect(col[8]).to eq(64646464646)
        expect(col.size).to eq(9)
      end

      it 'should raise an error for a datetime column with trailing boolean' do
        items = [nil, nil, '2018', 3.14159, '1957/9', 'True', '', '2:3', 64646464646]
        expect {
          Column.new(header: 'junk', items: items)
        }.to raise_error(/already typed as Numeric/)
      end
    end

    describe 'initialization of string' do
      it 'should initialize a good string column without trailing nils' do
        items = [nil, nil, 'hello', 'world77', 'about 1957/9', '2::3', '64646464646']
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('String')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq('hello')
        expect(col[3]).to eq('world77')
        expect(col[4]).to eq('about 1957/9')
        expect(col[5]).to eq('2::3')
        expect(col[6]).to eq('64646464646')
        expect(col.size).to eq(7)
      end

      it 'should initialize a good numeric column with trailing nils' do
        items = [nil, nil, 'hello', 'world77', '', nil, 'about 1957/9', '2::3', '64646464646']
        col = Column.new(header: 'junk', items: items)
        expect(col.header).to eq(:junk)
        expect(col.type).to eq('String')
        expect(col[0]).to eq(nil)
        expect(col[1]).to eq(nil)
        expect(col[2]).to eq('hello')
        expect(col[3]).to eq('world77')
        # Notice that for a String column, blanks are not treated as nils, but
        # as blank strings.
        expect(col[4]).to eq('')
        expect(col[5]).to eq(nil)
        expect(col[6]).to eq('about 1957/9')
        expect(col[7]).to eq('2::3')
        expect(col[8]).to eq('64646464646')
        expect(col.size).to eq(9)
      end

      it 'should raise an error for a string column with trailing numeric' do
        items = [nil, nil, 'hello', 'world77', 25, nil, 'about 1957/9',
                 '2::3', '64646464646']
        # Notice that for a String column, a number just gets converted to a
        # string and does not raise an error.
        col = nil
        expect {
          col = Column.new(header: 'junk', items: items)
        }.not_to raise_error
        # Like this:
        expect(col[4]).to eq('25')
      end
    end

    describe 'attribute access' do
      before :all do
        items = [nil, nil, '2018', 3.14159, '1957/9', nil, '', '2:3', 64646464646]
        @col = Column.new(header: 'junk Header 88', items: items)
      end

      it 'should be index-able' do
        expect(@col[0]).to eq(nil)
        expect(@col[1]).to eq(nil)
        expect(@col[2]).to eq(2018)
        expect(@col[3]).to eq(3.14159)
        expect(@col[4]).to eq(Rational(1957, 9))
        expect(@col[5]).to eq(nil)
        expect(@col[6]).to eq(nil)
        expect(@col[7]).to eq(Rational(2, 3))
        expect(@col[8]).to eq(64646464646)
        expect(@col[-1]).to eq(64646464646)
      end

      it 'should be convertible to an Array' do
        expect(@col.to_a.class).to eq(Array)
      end

      it 'should know its size etc' do
        expect(@col.size).to eq(9)
        expect(@col.last_i).to eq(8)
        expect(@col.empty?).to be false
        expect(Column.new(header: :junk).empty?).to be true
      end
    end

    describe 'enumerablity' do
      before :all do
        items = [nil, nil, '2018', 3.14159, '1957/9', nil, '',
                 '2:3', 64646464646, 87.6546464646465489798798646]
        @col = Column.new(header: 'junk Header 88', items: items)
      end

      it 'should be enumerable by enumerating its items' do
        expect(@col.respond_to?(:each)).to be true
        expect(@col.to_set.size).to eq(7)
        expect(@col.find_index(3.14159)).to eq(3)
      end
    end

    describe 'aggregates' do
      before :all do
        nums = [nil, nil, '2018', 3.14159, '1957/9', nil, '',
                '2:3', 64646464646, 87.654]
        @nums = Column.new(header: 'nums', items: nums)
        bools = [true, true, nil, false, 'no', nil]
        @bools = Column.new(header: 'bools', items: bools)
        dates = ['2017-01-22', '1957-09-22', '2011-05-18 23:14', nil,
                 '2011-02-18', nil]
        @dates = Column.new(header: 'dates', items: dates)
        strs = ['four', nil, 'score', 'and seven', nil, 'years', 'ago', nil]
        @strs = Column.new(header: 'strs', items: strs)
      end

      it 'should properly apply the first aggregate' do
        expect(@nums.first).to eq(2018)
        expect(@bools.first).to eq(true)
        expect(@dates.first).to eq(Date.new(2017, 1, 22))
        expect(@strs.first).to eq('four')
      end

      it 'should properly apply the last aggregate' do
        expect(@nums.last).to eq(87.654)
        expect(@bools.last).to eq(false)
        expect(@dates.last).to eq(Date.new(2011, 2, 18))
        expect(@strs.last).to eq('ago')
      end

      it 'should properly apply the rng aggregate' do
        expect(@nums.rng).to eq('2018..87.654')
        expect(@bools.rng).to eq('true..false')
        expect(@dates.rng).to eq('2017-01-22..2011-02-18')
        expect(@strs.rng).to eq('four..ago')
      end

      it 'should properly apply the sum aggregate' do
        expect(@nums.sum.round(4)).to eq(64646466972.9067)
        expect { @bools.sum }.to raise_error(/cannot be applied/)
        expect { @dates.sum }.to raise_error(/cannot be applied/)
        expect(@strs.sum).to eq('fourscoreand sevenyearsago')
      end

      it 'should properly apply the count aggregate' do
        expect(@nums.count).to eq(6)
        expect(@bools.count).to eq(4)
        expect(@dates.count).to eq(4)
        expect(@strs.count).to eq(5)
      end

      it 'should properly apply the min aggregate' do
        expect(@nums.min).to eq(2/3r)
        expect { @bools.min }.to raise_error(/cannot be applied/)
        expect(@dates.min).to eq(Date.parse('1957-09-22'))
        expect(@strs.min).to eq('ago')
      end

      it 'should properly apply the max aggregate' do
        expect(@nums.max).to eq(64646464646)
        expect { @bools.max }.to raise_error(/cannot be applied/)
        expect(@dates.max).to eq(Date.parse('2017-01-22'))
        expect(@strs.max).to eq('years')
      end

      it 'should properly apply the avg aggregate' do
        expect(@nums.avg.round(2)).to eq(10774411162.15)
        expect { @bools.avg }.to raise_error(/cannot be applied/)
        expect(@dates.avg).to eq(DateTime.parse('1999-04-28 18:00'))
        expect { @strs.avg }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the var aggregate' do
        expect(@nums.var.round(1)).to eq(BigDecimal('696527555176002510001.4'))
        expect { @bools.var }.to raise_error(/cannot be applied/)
        expect(@dates.var).to eq(103600564.25)
        expect { @strs.var }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the pvar aggregate' do
        expect(@nums.pvar.round(1)).to eq(BigDecimal('580439629313335424769.0'))
        expect { @bools.pvar }.to raise_error(/cannot be applied/)
        expect(@dates.pvar).to eq(77700423.1875)
        expect { @strs.pvar }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the dev aggregate' do
        expect(@nums.dev.round(1)).to eq(BigDecimal('26391808486.3'))
        expect { @bools.dev }.to raise_error(/cannot be applied/)
        expect(@dates.dev.round(2)).to eq(10178.44)
        expect { @strs.dev }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the pdev aggregate' do
        expect(@nums.pdev.round(1)).to eq(BigDecimal('24092314735.5'))
        expect { @bools.pdev }.to raise_error(/cannot be applied/)
        expect(@dates.pdev.round(2)).to eq(8814.78)
        expect { @strs.pdev }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the any? aggregate' do
        expect { @nums.any? }.to raise_error(/cannot be applied/)
        expect(@bools.any?).to eq(true)
        expect { @dates.any? }.to raise_error(/cannot be applied/)
        expect { @strs.any? }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the all? aggregate' do
        expect { @nums.all? }.to raise_error(/cannot be applied/)
        expect(@bools.all?).to eq(false)
        expect { @dates.all? }.to raise_error(/cannot be applied/)
        expect { @strs.all? }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the none? aggregate' do
        expect { @nums.none? }.to raise_error(/cannot be applied/)
        expect(@bools.none?).to eq(false)
        expect { @dates.none? }.to raise_error(/cannot be applied/)
        expect { @strs.none? }.to raise_error(/cannot be applied/)
      end

      it 'should properly apply the one? aggregate' do
        expect { @nums.one? }.to raise_error(/cannot be applied/)
        expect(@bools.one?).to eq(false)
        expect { @dates.one? }.to raise_error(/cannot be applied/)
        expect { @strs.one? }.to raise_error(/cannot be applied/)
      end
    end
  end
end
