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
1,2006-05-02,P,5000,5000,8.6000,2006-08-09-1-I
2,2006-05-03,P,5000,5000,8.4200,2006-08-09-1-I
3,2006-05-04,P,5000,5000,8.4000,2006-08-09-1-I
EOS
    expect(FatTable.from_csv_string(str).class).to eq(FatTable::Table)
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
end
