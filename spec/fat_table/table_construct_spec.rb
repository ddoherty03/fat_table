# frozen_string_literal: true

# Specs to test the building of Table from various inputs.
module FatTable
  RSpec.describe Table do
    describe 'initializer' do
      it 'initializes an empty table without headers' do
        expect(Table.new).to be_a(Table)
        expect(Table.new).to be_empty
      end

      it 'initializes and empty table with headers' do
        tab = Table.new('a', :b, '   four scORE', '**Batt@ry**')
        expect(tab).to be_a(Table)
        expect(tab).to be_empty
        heads = [:a, :b, :four_score, :battry]
        heads.each do |h|
          expect(tab.headers).to include(h)
          expect(tab.type(h)).to eq('NilClass')
        end
      end

      it 'can force a column to string type after initialization' do
        tab = Table.new('a', :b, '   four scORE', '**Batt@ry**', :zip)
        expect(tab).to be_a(Table)
        expect(tab).to be_empty
        heads = [:a, :b, :four_score, :zip]
        heads.each do |h|
          expect(tab.headers).to include(h)
          expect(tab.type(h)).to eq('NilClass')
        end
        tab << { zip: '66210' }
        tab << { a: '66210' }
        expect(tab.type(:a)).to eq('Numeric')
        expect(tab.type(:zip)).to eq('Numeric')
        tab.force_string!(:zip, :a)
        tab << { zip: '66210' }
        tab << { b: '06610' }
        tab << { zip: '06610' }
        expect(tab[0][:zip]).to eq('66210')
        expect(tab[1][:zip]).to eq('')
        expect(tab[1][:a]).to eq('66210')
        expect(tab[2][:zip]).to eq('66210')
        expect(tab[3][:a]).to be_nil
        expect(tab[3][:b]).to eq(6_610)
        expect(tab[3][:zip]).to be_nil
        # It preserves leading zeros
        expect(tab[4][:zip]).to eq('06610')
      end

      it 'can initialize from FatTable module method' do
        tab1 = FatTable.new
        expect(tab1).to be_a(Table)
        expect(tab1).to be_empty
      end

      it 'can initialize with headers and kw args from FatTable module method' do
        tab1 = FatTable.new(:a, :b, :c, b: '~')
        expect(tab1).to be_a(Table)
        expect(tab1).to be_empty
      end

      it 'can initialize with headers from FatTable module method' do
        tab = FatTable.new('a', :b, '   four scORE', '**Batt@ry**', :zip)
        expect(tab).to be_a(Table)
        expect(tab).to be_empty
        heads = [:a, :b, :four_score, :battry, :zip]
        expect(tab.headers).to eq(heads)
        heads.each do |h|
          expect(tab.headers).to include(h)
          expect(tab.type(h)).to eq('NilClass')
        end
      end
    end

    describe 'add_column' do
      it 'by adding columns' do
        headers = [:a, :b, :c, :d]
        tab = Table.new
        headers.each do |h|
          tab.add_column(Column.new(header: h))
        end
        expect(tab.headers).to eq headers
        expect(tab.columns.size).to eq 4
      end
    end

    describe 'add_row' do
      context 'with full rows' do
        it 'builds table correctly' do
          rows = [
            { a: 1, b: 2, c: 3, d: 4 },
            { a: 11, b: 12, c: 13, d: 14 },
            { a: 21, b: 22, c: 23, d: 24 },
            { a: 31, b: 32, c: 33, d: 34 },
            { a: 41, b: 42, c: 43, d: 44 },
          ]
          tab = Table.new
          rows.each do |r|
            tab << r
          end
          expect(tab.size).to eq 5
        end
      end

      context 'without full rows' do
        it 'by adding rows with missing keys', :aggregate_failures do
          rows = [
            { 'a': 1, c: 3, d: 4 },
            { a: 11, b: 12, d: 14 },
            { b: 22, c: 23, d: 24 },
            { a: 31, b: 32, c: 33 },
            { a: 41, b: 42, c: 43, d: 44 },
          ]
          tab = Table.new
          rows.each do |r|
            tab << r
          end
          expect(tab.size).to eq(5)
          expect(tab[0][:a]).to eq(1)
          expect(tab[2][:a]).to be_nil
          expect(tab[1][:b]).to eq(12)
          expect(tab[0][:b]).to be_nil
          expect(tab[0][:c]).to eq(3)
          expect(tab[1][:c]).to be_nil
          expect(tab[0][:d]).to eq(4)
          expect(tab[3][:d]).to be_nil
        end
      end
    end

    describe 'from CSV' do
      let(:csv_body) do
        <<~CSV
          Ref,Date,Code,RawShares,Shares,Price,Info
          1,2006-05-02,P,5000,5000,8.6000,2006-08-09-1-I
          2,2006-05-03,P,5000,5000,8.4200,2006-08-09-1-I
          3,2006-05-04,P,5000,5000,8.4000,2006-08-09-1-I
          4,2006-05-10,P,8600,8600,8.0200,2006-08-09-1-D
          5,2006-05-12,P,10000,10000,7.2500,2006-08-09-1-D
          6,2006-05-12,P,2000,2000,6.7400,2006-08-09-1-I
          7,2006-05-16,P,5000,5000,7.0000,2006-08-09-1-D
          8,2006-05-17,P,5000,5000,6.7000,2006-08-09-1-D
          9,2006-05-17,P,2000,2000,6.7400,2006-08-09-1-I
          10,2006-05-19,P,1000,1000,7.2500,2006-08-09-1-I
          11,2006-05-19,P,1000,1000,7.2500,2006-08-09-1-I
          12,2006-05-31,P,2000,2000,7.9200,2006-08-09-1-I
          13,2006-06-05,P,1000,1000,7.9200,2006-08-09-1-I
          14,2006-06-15,P,5000,5000,6.9800,2006-08-09-1-I
        CSV
      end

      let(:csv_no_headers) do
        <<~CSV
          1,2006-05-02,P,5000,5000,8.6000,2006-08-09-1-I
          2,2006-05-03,P,5000,5000,8.4200,2006-08-09-1-I
          3,2006-05-04,P,5000,5000,8.4000,2006-08-09-1-I
          4,2006-05-10,P,8600,8600,8.0200,2006-08-09-1-D
          5,2006-05-12,P,10000,10000,7.2500,2006-08-09-1-D
          6,2006-05-12,P,2000,2000,6.7400,2006-08-09-1-I
          7,2006-05-16,P,5000,5000,7.0000,2006-08-09-1-D
          8,2006-05-17,P,5000,5000,6.7000,2006-08-09-1-D
          9,2006-05-17,P,2000,2000,6.7400,2006-08-09-1-I
          10,2006-05-19,P,1000,1000,7.2500,2006-08-09-1-I
          11,2006-05-19,P,1000,1000,7.2500,2006-08-09-1-I
          12,2006-05-31,P,2000,2000,7.9200,2006-08-09-1-I
          13,2006-06-05,P,1000,1000,7.9200,2006-08-09-1-I
          14,2006-06-15,P,5000,5000,6.9800,2006-08-09-1-I
        CSV
      end

      let(:bad_csv_body) do
        <<~CSV
          nothing much
        CSV
      end

      it 'creates a Table from a CSV string with headers' do
        tab = Table.from_csv_string(csv_body)
        expect(tab.number_of_groups).to eq(1)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :rawshares, :ref, :shares]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:code].class).to eq String
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          unless row[:rawshares].nil?
            expect(row[:rawshares].is_a?(Numeric)).to be true
          end
          expect(row[:price].is_a?(Numeric)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
        end
      end

      it 'creates a Table from a CSV string without headers' do
        tab = Table.from_csv_string(csv_no_headers, has_headers: false)
        expect(tab.class).to eq(Table)
        expect(tab[0][:col_1]).to eq(1)
        expect(tab[0][:col_7]).to eq('2006-08-09-1-I')
        expect(tab.number_of_groups).to eq(1)
      end

      # it 'raises an exception on a bad CSV string' do
      #   expect { Table.from_csv_string(bad_csv_body) }.to raise_exception(NoTable)
      # end

      it 'creates a Table from a CSV file' do
        File.write('/tmp/junk.csv', csv_body)
        tab = Table.from_csv_file('/tmp/junk.csv')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :rawshares, :ref, :shares]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:code].class).to eq String
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          unless row[:rawshares].nil?
            expect(row[:rawshares].is_a?(Numeric)).to be true
          end
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end
    end

    describe 'from Org without tolerance' do
      let(:org_body) do
        <<~ORG
          * Morgan Transactions
            :PROPERTIES:
            :TABLE_EXPORT_FILE: morgan.csv
            :END:

            #+TBLNAME: morgan_tab
            | Ref |       Date | Code |     Raw | Shares |    Price | Info   |
            |-----+------------+------+---------+--------+----------+--------|
            |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500 | ZMPEF1 |
            |  30 | 2013-05-02 | P    | 118,186 |    388 | 11.85000 | ZMPEF1 |
            |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ZMPEF2 |
            |  32 | 2013-05-02 | P    |  50,651 |    286 | 11.85000 | ZMPEF2 |
            |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ZMEAC  |
            |  34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ZMEAC  |
            |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ZMEAC  |
            |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ZMEAC  |
            |  37 | 2013-05-23 | S    |  23,054 |     61 | 26.80150 | ZMEAC  |
            |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ZMEAC  |
            |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ZMEAC  |
            |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ZMEAC  |
            |  41 | 2013-05-29 | S    |  15,900 |     42 | 24.58020 | ZMEAC  |
            |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ZMEAC  |

          * Another Heading
        ORG
      end

      let(:org_body_with_groups) do
        <<~ORG
          #+TBLNAME: morgan_tab
          |-----+------------+------+---------+--------+----------+--------|
          | Ref |       Date | Code |     Raw | Shares |    Price | Info   |
          |-----+------------+------+---------+--------+----------+--------|
          |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500 | ZMPEF1 |
          |-----+------------+------+---------+--------+----------+--------|
          |  30 | 2013-05-02 | P    | 118,186 |    388 | 11.85000 | ZMPEF1 |
          |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ZMPEF2 |
          |  32 | 2013-05-02 | P    |  50,651 |    286 | 11.85000 | ZMPEF2 |
          |-----+------------+------+---------+--------+----------+--------|
          |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ZMEAC  |
          |  34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ZMEAC  |
          |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ZMEAC  |
          |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ZMEAC  |
          |  37 | 2013-05-23 | S    |  23,054 |     61 | 26.80150 | ZMEAC  |
          |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ZMEAC  |
          |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
          |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ZMEAC  |
          |  41 | 2013-05-29 | S    |  15,900 |     42 | 24.58020 | ZMEAC  |
          |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
        ORG
      end

      it 'creates from an Org string' do
        tab = Table.from_org_string(org_body)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:code].class).to eq String
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          unless row[:rawshares].nil?
            expect(row[:rawshares].is_a?(Numeric)).to be true
          end
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end

      it 'creates from an Org string with groups' do
        tab = Table.from_org_string(org_body_with_groups)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        expect(tab.number_of_groups).to eq(4)
        sub_cols = tab.group_cols(:shares)
        expect(sub_cols[0].size).to eq(1)
        expect(sub_cols[1].size).to eq(3)
        expect(sub_cols[2].size).to eq(7)
        expect(sub_cols[3].size).to eq(3)
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:code].class).to eq String
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          unless row[:rawshares].nil?
            expect(row[:rawshares].is_a?(Numeric)).to be true
          end
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end

      it 'creates from an Org file' do
        File.write('/tmp/junk.org', org_body)
        tab = Table.from_org_file('/tmp/junk.org')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.rows[0].keys.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:code].class).to eq String
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          unless row[:rawshares].nil?
            expect(row[:rawshares].is_a?(Numeric)).to be true
          end
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end

      it 'raises error on a bad Org file' do
        fname = File.expand_path(File.join(__dir__, '../example_files/not_a_table.org'))
        expect { Table.from_org_file(fname) }.to raise_exception(NoTable)
      end

      it 'adds group boundaries on reading from org text' do
        tab = Table.from_org_string(org_body_with_groups)
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(7)
        expect(tab.groups[3].size).to eq(3)
      end

      it 'sets T F columns to Boolean' do
        cwd = File.dirname(__FILE__)
        dwtab = Table.from_org_file(cwd + '/../example_files/datawatch.org')
        expect(dwtab.column(:g10).type).to eq('Boolean')
        expect(dwtab.column(:qp10).type).to eq('Boolean')
        dwo = dwtab.where('qp10 || g10')
        dwo.rows.each do |row|
          expect(row[:qp10].class.to_s).to match(/TrueClass|FalseClass/)
        end
      end
    end

    describe 'from Org with tolerance' do
      let(:org_body) do
        <<~ORG
          * Morgan Transactions
            :PROPERTIES:
            :TABLE_EXPORT_FILE: morgan.csv
            :END:

            #+TBLNAME: morgan_tab
            | Ref |       Date | Code |     Raw | Shares |    Price | Info   |
            |-----+------------+------+---------+--------+----------+--------|
            |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500 | ZMPEF1 |
            |  30 | 2013-05-02 | P    | 118,186 |    388 | 11.85000 | ZMPEF1 |
            |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ZMPEF2 |
            |  32 | 2013-05-02 | P    |  50,651 |    286 | 11.85000 | ZMPEF2 |
            |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ZMEAC  |
            |  T34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ZMEAC  |
            |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ZMEAC  |
            |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ZMEAC  |
            |  37 | 2013-05-23 | S    |  Some Junk |     61 | 26.80150 | ZMEAC  |
            |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ZMEAC  |
            |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ZMEAC  |
            |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ZMEAC  |
            |  41 | 2013-05-29 | S    |  15,900 |     42 | 24.58020 | ZMEAC  |
            |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ZMEAC  |

          * Another Heading
        ORG
      end

      let(:org_body_with_groups) do
        <<~ORG
          #+TBLNAME: morgan_tab
          |-----+------------+------+---------+--------+----------+--------|
          | Ref |       Date | Code |     Raw | Shares |    Price | Info   |
          |-----+------------+------+---------+--------+----------+--------|
          |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500 | ZMPEF1 |
          |-----+------------+------+---------+--------+----------+--------|
          |  30 | 2013-05-02 | P    | 118,186 |    388 | 11.85000 | ZMPEF1 |
          |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ZMPEF2 |
          |  32 | 2013-05-02 | P    |  50,651 |    286 | 11.85000 | ZMPEF2 |
          |-----+------------+------+---------+--------+----------+--------|
          |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ZMEAC  |
          |  T34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ZMEAC  |
          |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ZMEAC  |
          |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ZMEAC  |
          |  37 | 2013-05-23 | S    |  More Junk |     61 | 26.80150 | ZMEAC  |
          |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ZMEAC  |
          |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
          |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ZMEAC  |
          |  41 | 2013-05-29 | S    |  Not what I expected |     42 | 24.58020 | ZMEAC  |
          |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
        ORG
      end

      # This has missing and extra separators on some rows: refs 30, 32, and
      # 38 should be skipped.
      let(:bad_org_body) do
        <<~ORG
          #+TBLNAME: bad_tab
          |-----+------------+------+---------+--------+----------+--------|
          | Ref |       Date | Code |     Raw | Shares |    Price | Info   |
          |-----+------------+------+---------+--------+----------+--------|
          |  29 | 2013-05-02 | P    | 795,546 |  2,609 |  1.18500  ZMPEF1 |
          |-----+------------+------+---------+--------+----------+--------|
          |  30 | 2013-05-02 | P    || 118,186 |    388 | 11.85000 | ZMPEF1 |
          |  31 | 2013-05-02 | P    | 340,948 |  1,926 |  1.18500 | ZMPEF2 |
          |  32 | 2013-05-02 | P      50,651 |    286 | 11.85000 | ZMPEF2 |
          |-----+------------+------+---------+--------+----------+--------|
          |  33 | 2013-05-20 | S    |  12,000 |     32 | 28.28040 | ZMEAC  |
          |  34 | 2013-05-20 | S    |  85,000 |    226 | 28.32240 | ZMEAC  |
          |  35 | 2013-05-20 | S    |  33,302 |     88 | 28.63830 | ZMEAC  |
          |  36 | 2013-05-23 | S    |   8,000 |     21 | 27.10830 | ZMEAC  |
          |  37 | 2013-05-23  S    |  7,250 |     61 | 26.80150 | ZMEAC  |
          |  38 | 2013-05-23 | S    |  39,906 |    106 | 25.17490 | ZMEAC  | | |
          |  39 | 2013-05-29 | S    |  13,459 |     36 | 24.74640 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
          |  40 | 2013-05-29 | S    |  15,700 |     42 | 24.77900 | ZMEAC  |
          |  42 | 2013-05-30 | S    |   6,679 |     18 | 25.04710 | ZMEAC  |
          |-----+------------+------+---------+--------+----------+--------|
        ORG
      end

      it 'creates from an Org string' do
        tab = Table.from_org_string(org_body, ref: '~', raw: '~')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        tab.rows.each do |row|
          expect(row[:code].class).to eq String
          expect(tab.column(:ref).type).to eq('Numeric')
          expect(tab.column(:raw).type).to eq('Numeric')
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end

      it 'creates from an Org string with specified types' do
        tab = Table.from_org_string(org_body, ref: 'str~', raw: 'num~')
        expect(tab.class).to eq(Table)
        expect(tab.type(:ref)).to eq('String')
        expect(tab.tolerant_col?(:ref)).to be true
        expect(tab.type(:raw)).to eq('Numeric')
        expect(tab.tolerant_col?(:raw)).to be true

        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        tab.rows.each do |row|
          expect(row[:code].class).to eq String
          expect(tab.column(:ref).type).to eq('String')
          expect(tab.column(:raw).type).to eq('Numeric')
          expect(row[:date].class).to eq Date
          expect(row[:shares].is_a?(Numeric)).to be true
          expect(row[:price].is_a?(BigDecimal)).to be true
          expect([Numeric, String].any? { |t| row[:ref].is_a?(t) }).to be true
          expect(row[:info].class).to eq String
        end
      end

      it 'creates from an Org string with module method' do
        tab = FatTable.from_org_string(org_body, ref: '~', raw: '~')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        expect(tab.column(:ref).type).to eq('Numeric')
        expect(tab.column(:raw).type).to eq('Numeric')
        expect(tab[:ref].select { |i| i.is_a?(String) }).not_to be_empty
        expect(tab[:raw].select { |i| i.is_a?(String) }).not_to be_empty
        expect(tab[:date].select { |i| i.is_a?(String) }).to be_empty
        expect(tab[:price].select { |i| i.is_a?(String) }).to be_empty
        expect(tab[:shares].select { |i| i.is_a?(String) }).to be_empty
      end

      it 'creates from an Org string with groups' do
        tab = Table.from_org_string(org_body_with_groups, omni: '~')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        expect(tab.number_of_groups).to eq(4)
        sub_cols = tab.group_cols(:shares)
        expect(sub_cols[0].size).to eq(1)
        expect(sub_cols[1].size).to eq(3)
        expect(sub_cols[2].size).to eq(7)
        expect(sub_cols[3].size).to eq(3)
        expect(tab.column(:ref).type).to eq('Numeric')
        expect(tab.column(:raw).type).to eq('Numeric')
        expect(tab[:ref].select { |i| i.is_a?(String) }).not_to be_empty
        expect(tab[:raw].select { |i| i.is_a?(String) }).not_to be_empty
        expect(tab[:date].select { |i| i.is_a?(String) }).to be_empty
        expect(tab[:price].select { |i| i.is_a?(String) }).to be_empty
        expect(tab[:shares].select { |i| i.is_a?(String) }).to be_empty
      end

      it 'creates from an Org file' do
        File.write('/tmp/junk.org', org_body)
        tab = Table.from_org_file('/tmp/junk.org', ref: '~', raw: '~', shares: '~')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.rows[0].keys.sort)
          .to eq [:code, :date, :info, :price, :raw, :ref, :shares]
        expect(tab.column(:ref).type).to eq('Numeric')
        expect(tab.column(:raw).type).to eq('Numeric')
        expect(tab.column(:shares).type).to eq('Numeric')
        expect(tab.column(:price).type).to eq('Numeric')
        expect(tab.column(:info).type).to eq('String')
      end

      it 'adds group boundaries on reading from org text' do
        tab = Table.from_org_string(org_body_with_groups, ref: '~', raw: '~', shares: '~')
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(7)
        expect(tab.groups[3].size).to eq(3)
      end

      it 'skips rows that are malformed' do
        tab = Table.from_org_string(bad_org_body)
        good_refs = [31, 33, 34, 35, 36, 39, 40, 42]
        expect(tab[:ref]).to eq(good_refs)
        expect(tab[:ref]).not_to include(30)
        expect(tab[:ref]).not_to include(32)
        expect(tab[:ref]).not_to include(38)
      end
    end

    describe 'marking boundaries' do
      # This is pretty subtle
      it 'adds boundaries manually' do
        tab = FatTable.new
        expect(tab.number_of_groups).to eq(0)
        # Does nothing on an empty table
        tab.mark_boundary
        expect(tab.number_of_groups).to eq(0)
        tab << { a: 1, b: 2, c: 3 }
        expect { tab.mark_boundary(5) }.to raise_error(/can't mark/)
        tab.mark_boundary
        expect(tab.number_of_groups).to eq(1)
        tab << { a: 3, b: 4, c: 5 }
        tab.mark_boundary
        expect(tab.number_of_groups).to eq(2)
        tab << { a: 6, b: 7, c: 8 }
        tab << { a: 9, b: 0, c: 1 }
        expect(tab.number_of_groups).to eq(3)

        # This does not change the number of groups because the last row is
        # already marked.
        tab.mark_boundary
        expect(tab.number_of_groups).to eq(3)

        # Adding multiple boundaries to the end does nothing.
        tab.mark_boundary
        tab.mark_boundary
        tab.mark_boundary
        tab.mark_boundary
        expect(tab.number_of_groups).to eq(3)

        # Adding rows adds a new implict boundary at the end, so after these,
        # we should have 4 groups.
        tab << { a: 6, b: 7, c: 8 }
        tab << { a: 9, b: 0, c: 1 }
        tab << { a: 6, b: 7, c: 8 }
        tab << { a: 9, b: 0, c: 1 }
        tab << { a: 6, b: 7, c: 8 }
        tab << { a: 9, b: 0, c: 1 }
        tab << { a: 6, b: 7, c: 8 }
        tab << { a: 9, b: 0, c: 1 }
        expect(tab.number_of_groups).to eq(4)

        # Mark at a specified row before the last; should add a group.
        tab.mark_boundary(7)
        expect(tab.number_of_groups).to eq(5)
      end
    end

    describe 'from ruby data structures' do
      let(:aoa_with_nil_hrule) do
        [
          ['First', 'Second', 'Third'],
          nil,
          ['1', '2', '3.2'],
          ['4', '5', '6.4'],
          ['7', '8', '9.0'],
          [10, 11, 12.1],
        ]
      end
      let(:aoa_sans_header) do
        [
          ['1', '2', '3.2'],
          ['4', '5', '6.4'],
          ['7', '8', '9.0'],
          [7, 8, 9.3],
        ]
      end

      it 'creates from an Array of Arrays with nil-marked header' do
        tab = Table.from_aoa(aoa_with_nil_hrule, hlines: true)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.groups.size).to eq(1)
        expect(tab.headers.sort).to eq [:first, :second, :third]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:first].is_a?(Numeric)).to be true
          expect(row[:second].is_a?(Numeric)).to be true
          expect(row[:third].is_a?(BigDecimal)).to be true
        end
      end

      it 'creates from an Array of Arrays sans Header' do
        # Set second param to true to say headers must be marked by an hline,
        # otherwise headers will be synthesized.
        tab = Table.from_aoa(aoa_sans_header, hlines: true)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.headers.sort).to eq [:col_1, :col_2, :col_3]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:col_1].is_a?(Numeric)).to be true
          expect(row[:col_2].is_a?(Numeric)).to be true
          expect(row[:col_3].is_a?(BigDecimal)).to be true
        end
      end

      it 'creates from an Array of Hashes' do
        aoh = [
          { a: '1', 'Two words' => '2', c: '3.2' },
          { a: '4', 'Two words' => '5', c: '6.4' },
          { a: '7', 'Two words' => '8', c: '9.0' },
          { a: 10, 'Two words' => 11, c: 12.4 },
        ]
        tab = Table.from_aoh(aoh)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.rows[0].keys.sort).to eq [:a, :c, :two_words]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:a].is_a?(Numeric)).to be true
          expect(row[:two_words].is_a?(Numeric)).to be true
          expect(row[:c].is_a?(BigDecimal)).to be true
        end
      end
    end

    describe 'from ruby aoa data structures with groups' do
      let(:tab) do
        aoa = [
          %w[Ref Date Code Raw Shares Price Info Bool],
          nil,
          [1, '2013-05-02', 'P', 795_546.20, 795_546.2, 1.1850, 'ZMPEF1', 'T'],
          nil,
          [2,  '2013-05-02', 'P', 118_186.40, 118_186.4, 11.8500, 'ZMPEF1', 'T'],
          [7,  '2013-05-20', 'S', 12_000.00,  5046.00,   28.2804, 'ZMEAC',  'F'],
          [8,  '2013-05-20', 'S', 85_000.00,  35_742.50, 28.3224, 'ZMEAC',  'T'],
          nil,
          [9,  '2013-05-20', 'S', 33_302.00,  14_003.49, 28.6383, 'ZMEAC',  'T'],
          [10, '2013-05-23', 'S', 8000.00,    3364.00,   27.1083, 'ZMEAC',  'T'],
          [11, '2013-05-23', 'S', 23_054.00,  9694.21,   26.8015, 'ZMEAC',  'F'],
          [12, '2013-05-23', 'S', 39_906.00,  16_780.47, 25.1749, 'ZMEAC',  'T'],
          [13, '2013-05-29', 'S', 13_459.00,  5659.51,   24.7464, 'ZMEAC',  'T'],
          [14, '2013-05-29', 'S', 15_700.00,  6601.85,   24.7790, 'ZMEAC',  'F'],
          [15, '2013-05-29', 'S', 15_900.00,  6685.95,   24.5802, 'ZMEAC',  'T'],
          nil,
          [16, '2013-05-30', 'S', 6_679.00, 2808.52, 25.0471, 'ZMEAC', 'T'],
        ]
        Table.from_aoa(aoa, hlines: true)
      end

      it 'properly forms the groups' do
        expect(tab.number_of_groups).to eq(4)
      end
    end

    describe 'from ruby aoh data structures with groups' do
      let(:tab) do
        aoh = [
          {
            ref: 1,
            date: '2013-05-02',
            code: 'P',
            shares: 795_546.20,
            raw: 795_546.2,
            price: 1.1850,
            info: 'ZMPEF1',
            bool: 'T'
          },
          nil,
          {
            ref: 2,
            date: '2013-05-02',
            code: 'P',
            shares: 118_186.40,
            raw: 118_186.4,
            price: 11.8500,
            info: 'ZMPEF1',
            bool: 'T'
          },
          {
            ref: 7,
            date: '2013-05-20',
            code: 'S',
            shares: 12_000.00,
            raw: 5046.00,
            price: 28.2804,
            info: 'ZMEAC',
            bool: 'F'
          },
          {
            ref: 8,
            date: '2013-05-20',
            code: 'S',
            shares: 85_000.00,
            raw: 35_742.50,
            price: 28.3224,
            info: 'ZMEAC',
            bool: 'T'
          },
          nil,
          {
            ref: 9,
            date: '2013-05-20',
            code: 'S',
            shares: 33_302.00,
            raw: 14_003.49,
            price: 28.6383,
            info: 'ZMEAC',
            bool: 'T'
          },
          {
            ref: 10,
            date: '2013-05-23',
            code: 'S',
            shares: 8000.00,
            raw: 3364.00,
            price: 27.1083,
            info: 'ZMEAC',
            bool: 'T'
          },
          {
            ref: 11,
            date: '2013-05-23',
            code: 'S',
            shares: 23_054.00,
            raw: 9694.21,
            price: 26.8015,
            info: 'ZMEAC',
            bool: 'F'
          },
          {
            ref: 12,
            date: '2013-05-23',
            code: 'S',
            shares: 39_906.00,
            raw: 16_780.47,
            price: 25.1749,
            info: 'ZMEAC',
            bool: 'T'
          },
          {
            ref: 13,
            date: '2013-05-29',
            code: 'S',
            shares: 13_459.00,
            raw: 5659.51,
            price: 24.7464,
            info: 'ZMEAC',
            bool: 'T'
          },
          {
            ref: 14,
            date: '2013-05-29',
            code: 'S',
            shares: 15_700.00,
            raw: 6601.85,
            price: 24.7790,
            info: 'ZMEAC',
            bool: 'F'
          },
          {
            ref: 15,
            date: '2013-05-29',
            code: 'S',
            shares: 15_900.00,
            raw: 6685.95,
            price: 24.5802,
            info: 'ZMEAC',
            bool: 'T'
          },
          nil,
          {
            ref: 16,
            date: '2013-05-30',
            code: 'S',
            shares: 6_679.00,
            raw: 2808.52,
            price: 25.0471,
            info: 'ZMEAC',
            bool: 'T'
          },
        ]
        Table.from_aoh(aoh, hlines: true)
      end

      it 'properly forms the groups' do
        expect(tab.number_of_groups).to eq(4)
        sub_cols = tab.group_cols(:shares)
        expect(sub_cols[0].size).to eq(1)
        expect(sub_cols[1].size).to eq(3)
        expect(sub_cols[2].size).to eq(7)
        expect(sub_cols[3].size).to eq(1)
      end
    end

    describe 'from SQL' do
      describe 'all adapters' do
        it 'raises exception if adapters not present', :db do
          ['pg', 'sqlite3'].each do |adapter|
            begin
              got_gem = require adapter
            rescue LoadError
              got_gem = false
            end
            next if got_gem

            expect {
              FatTable.connect(adapter: adapter, database: 'fat_table_spec')
            }.to raise_error FatTable::TransientError, /need to install/
          end
          expect {
            FatTable.connect(adapter: 'jdbc', database: 'fat_table_spec')
          }.to raise_error Sequel::AdapterNotFound, /cannot load/
        end
      end

      context 'with postgres', :postgres do
        let(:out_file) { Pathname("#{__dir__}/../tmp/psql.out").cleanpath }
        let(:sql_file) { Pathname("#{__dir__}/../example_files/trades.sql").cleanpath }
        let!(:db_success) do
          system "createdb -e fat_table_spec >#{out_file} 2>&1"
          system "psql -a -d fat_table_spec -f #{sql_file} >>#{out_file} 2>&1"
        end

        after do
          # Drop the db
          if FatTable.db
            FatTable.db.disconnect
            system "dropdb -e fat_table_spec >>#{out_file} 2>&1"
          end
        end

        it 'creates from a postgres SQL query', :db, :postgres do
          expect(db_success).to be true
          # FatTable.db = Sequel.postgres(database: 'fat_table_spec')
          FatTable.connect(adapter: 'postgres', database: 'fat_table_spec')
          system("echo URI: #{FatTable.db.uri} >>#{out_file}")
          system("echo Tables: #{FatTable.db.tables} >>#{out_file}")
          system "psql -a -d fat_table_spec -c 'select * from trades where shares > 10000' >>#{out_file} 2>&1"
          query = <<~SQL.strip_heredoc
            SELECT ref, date, code, price, shares
            FROM trades
            WHERE shares > 1000
          SQL
          tab = Table.from_sql(query)
          expect(tab.class).to eq(Table)
          expect(tab.rows.size).to be > 100
        end
      end

      context 'with sqlite' do
        it 'creates from a sqlite SQL query', :db do
          db_file = File.expand_path(File.join(__dir__, '../example_files/trades2.db'))
          # FatTable.db = Sequel.postgres(database: 'fat_table_spec')
          FatTable.connect(adapter: 'sqlite', database: db_file)
          query = <<-SQL.strip_heredoc
            SELECT date, code, price, shares
            FROM trans
            WHERE shares > 1000
          SQL
          tab = Table.from_sql(query)
          expect(tab.class).to eq(Table)
          expect(tab.rows.size).to be > 8
        end
      end
    end
  end
end
