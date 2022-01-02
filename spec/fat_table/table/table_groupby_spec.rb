module FatTable
  describe Table do
    describe 'group_by' do
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

      it 'should be able to group by equal columns' do
        tab2 = @tab.group_by(:date, :code, shares: :sum, price: :avg, ref: :rng,
                             bool: :all?)
        expect(tab2.headers).to eq([:date, :code, :sum_shares, :avg_price,
                                    :rng_ref, :all_bool,])
        expect(tab2[0][:sum_shares]).to eq(913732.6)
        expect(tab2[1][:sum_shares]).to eq(54791.99)
        expect(tab2[0][:avg_price]).to eq(6.5175)
        expect(tab2[1][:avg_price]).to eq(28.4137)
      end
    end
  end
end
