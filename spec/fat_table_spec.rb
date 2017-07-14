require 'spec_helper'

RSpec.describe FatTable do
  it 'has a version number' do
    expect(FatTable::VERSION).not_to be nil
  end

  it 'can invoke new constructor' do
    expect(FatTable.new.class).to eq(FatTable::Table)
  end

  it 'can invoke from_csv_file constructor' do
    fname = "#{__dir__}/example_files/wpcs.csv"
    expect(FatTable.from_csv_file(fname).class)
      .to eq(FatTable::Table)
  end

  it 'can invoke from_csv_string constructor' do
    str = <<-EOS
Ref,Date,Code,RawShares,Shares,Price,Info
1,5/2/2006,P,5000,5000,8.6000,2006-08-09-1-I
2,05/03/2006,P,5000,5000,8.4200,2006-08-09-1-I
3,5/4/2006,P,5000,5000,8.4000,2006-08-09-1-I
EOS
    tab = FatTable.from_csv_string(str)
    expect(tab.class).to eq(FatTable::Table)
    expect(tab.column(:date).type).to eq('DateTime')
  end

  it 'can construct from_org_file' do
    fname = "#{__dir__}/example_files/goldberg.org"
    expect(FatTable.from_org_file(fname).class)
      .to eq(FatTable::Table)
  end

  it 'can construct from_org_string' do
    str = <<-EOS
#+CAPTION: Goldberg
#+ATTR_LATEX: :font \footnotesize
#+NAME: goldberg
|     Ref |       Date | Code |   Shares | Price | Info |
|---------+------------+------+----------+-------+------|
| 2841381 | 2016-11-04 | P    |   2603.0 |  6.46 |      |
| 2841382 | 2016-11-04 | S    |   3800.0 |  6.45 |      |
| 2841500 | 2016-11-04 | P    |   3100.0 |  6.55 |      |
EOS
    expect(FatTable.from_org_string(str).class)
      .to eq(FatTable::Table)
  end

  it 'can construct from array of arrays' do
    aoa = [[:a, :b, :c], [1, 2, 3], [4, 5, 6]]
    expect(FatTable.from_aoa(aoa).class)
      .to eq(FatTable::Table)
    aoa_h = [[:a, :b, :c], nil, [1, 2, 3], [4, 5, 6]]
    expect(FatTable.from_aoa(aoa_h, hlines: true).class)
      .to eq(FatTable::Table)
  end

  it 'can construct from array of hashes' do
    aoh = [{ a: 1, b: 2, c: 3 }, { a: 4, b: 5, c: 6 }]
    expect(FatTable.from_aoh(aoh).class)
      .to eq(FatTable::Table)
  end

  it 'can construct from Table' do
    aoh = [{ a: 1, b: 2, c: 3 }, { a: 4, b: 5, c: 6 }]
    tab = FatTable.from_aoh(aoh)
    expect(FatTable.from_table(tab).class)
      .to eq(FatTable::Table)
  end

  it 'should work on README example' do
    data =
      [['Date', 'Code', 'Raw', 'Shares', 'Price', 'Info', 'Bool'],
       ['2013-05-29', 'S', 15_700.00, 6601.85, 24.7790, 'ENTITY3', 'F'],
       ['2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ENTITY1', 'T'],
       ['2013-05-20', 'S', 12_000.00, 5046.00, 28.2804, 'ENTITY3', 'F'],
       ['2013-05-23', 'S', 8000.00, 3364.00, 27.1083, 'ENTITY3', 'T'],
       ['2013-05-23', 'S', 39_906.00, 16_780.47, 25.1749, 'ENTITY3', 'T'],
       ['2013-05-20', 'S', 85_000.00, 35_742.50, 28.3224, 'ENTITY3', 'T'],
       ['2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ENTITY1', 'T'],
       ['2013-05-29', 'S', 13_459.00, 5659.51, 24.7464, 'ENTITY3', 'T'],
       ['2013-05-20', 'S', 33_302.00, 14_003.49, 28.6383, 'ENTITY3', 'T'],
       ['2013-05-29', 'S', 15_900.00, 6685.95, 24.5802, 'ENTITY3', 'T'],
       ['2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ENTITY3', 'T'],
       ['2013-05-23', 'S', 23_054.00, 9694.21, 26.8015, 'ENTITY3', 'F']]

    table = FatTable.from_aoa(data) \
              .where('shares > 2000') \
              .order_by(:date, :code) \
              .select(:date, :code, :shares, :price, :bool, ref: '@row') \
              .select(:ref, :date, :code, :shares, :price, :bool)

    out = table.to_text do |fmt|
      fmt.avg_footer(:price)
      fmt.sum_footer(:shares)
      fmt.sum_gfooter(:shares)
      fmt.avg_gfooter(:price)
      fmt.format(ref: 'CB', numeric: 'R')
      fmt.format_for(:header, string: 'CB')
      fmt.format_for(:body, shares: ',0.2R', price: '0.4', )
      fmt.format_for(:footer, shares: 'B,0.2', price: 'B0.4', )
      fmt.format_for(:gfooter, shares: 'B,0.2', price: 'B0.4', )
    end
  end
end
