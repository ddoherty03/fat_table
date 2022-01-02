module FatTable
  describe Table do
    describe 'where' do
      before :all do
        aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
          [2, '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1', 'T'],
          [7, '2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ZMEAC', 'F'],
          [8, '2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ZMEAC', 'T'],
          [9, '2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ZMEAC', 'T'],
          [10, '2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ZMEAC', 'T'],
          [11, '2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ZMEAC', 'F'],
          [12, '2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ZMEAC', 'T'],
          [13, '2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ZMEAC', 'T'],
          [14, '2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ZMEAC', 'F'],
          [15, '2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ZMEAC', 'T'],
          [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T'],
        ]
        @tab = Table.from_aoa(aoa)
      end

      it 'should be able to filter rows by expression' do
        tab2 = @tab.where("date <= Date.parse('2013-05-20')")
        expect(tab2[:date].count).to eq(5)
      end

      it 'should where by boolean columns' do
        tab2 = @tab.where('!bool || code == "P"')
        expect(tab2.columns.size).to eq(8)
        expect(tab2.rows.size).to eq(5)
        tab2 = @tab.where('code == "S" && raw < 10_000')
        expect(tab2.columns.size).to eq(8)
        expect(tab2.rows.size).to eq(2)
        tab2 = @tab.where('@row > 10')
        expect(tab2.columns.size).to eq(8)
        expect(tab2.rows.size).to eq(2)
        tab2 = @tab.where('info =~ /zmeac/i')
        expect(tab2.columns.size).to eq(8)
        expect(tab2.rows.size).to eq(10)
        tab2 = @tab.where('info =~ /xxxx/')
        expect(tab2.columns.size).to eq(8)
        expect(tab2.rows.size).to eq(0)
      end

      it 'where clause with row and group' do
        tab = @tab.order_by(:date, :code)
        tab2 = tab.where('@row > 10')
        expect(tab2.rows.size).to eq(2)
        tab2 = tab.where('@group == 3')
        expect(tab2.rows.size).to eq(3)
      end
    end
  end
end
