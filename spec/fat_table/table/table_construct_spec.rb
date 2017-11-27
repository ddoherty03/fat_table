require 'spec_helper'

module FatTable
  describe Table do
    before :all do
      @csv_file_body = <<~CSV
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
        15,2006-06-16,P,1000,1000,6.9300,2006-08-09-1-I
        16,2006-06-16,P,1000,1000,6.9400,2006-08-09-1-I
        17,2006-06-29,P,4000,4000,7.0000,2006-08-09-1-I
        18,2006-07-14,P,2000,2000,6.2000,2006-08-09-1-D
        19,2006-08-03,P,1400,1400,4.3900,2006-08-09-1-D
        20,2006-08-07,P,1100,1100,4.5900,2006-08-09-1-D
        21,2006-08-08,P,16000,16000,4.7000,2006-08-21-1-D
        22,2006-08-08,S,16000,16000,4.7000,2006-08-21-1-I
        23,2006-08-15,P,16000,16000,4.8000,2006-08-21-1-D
        24,2006-08-15,S,16000,16000,4.8000,2006-08-21-1-I
        25,2006-08-16,P,2100,2100,5.2900,2006-08-21-1-I
        26,2006-08-17,P,2900,2900,5.7000,2006-08-21-1-I
        27,2006-08-23,P,8000,8000,5.2400,2006-08-25-1-D
        28,2006-08-23,S,8000,8000,5.2400,2006-08-29-1-I
        29,2006-08-28,P,1000,1000,5.4000,2006-08-29-1-D
        30,2006-08-29,P,2000,2000,5.4000,2006-08-30-1-D
        31,2006-08-29,S,2000,2000,5.4000,2006-08-30-1-I
        32,2006-09-05,P,2700,2700,5.7500,2006-09-06-1-I
        33,2006-09-11,P,4000,4000,5.7200,2006-09-15-1-D
        34,2006-09-11,S,4000,4000,5.7200,2006-09-15-1-I
        35,2006-09-12,P,3000,3000,5.4800,2006-09-15-2-I
        36,2006-09-13,P,1700,1700,5.4100,2006-09-15-2-I
        37,2006-09-20,P,7500,7500,5.4900,2006-09-21-1-I
        38,2006-12-07,S,6000,6000,7.8900,2006-12-11-1-I
        39,2006-12-11,S,100,100,8.0000,2006-12-11-1-I
        40,2007-01-29,P,2500,2500,12.1000,2007-04-27-1-I
        41,2007-01-31,P,2500,2500,13.7000,2007-04-27-1-I
        42,2007-02-02,P,4000,4000,15.1500,2007-04-27-1-I
        43,2007-02-06,P,5000,5000,14.9500,2007-04-27-1-I
        44,2007-02-07,P,400,400,15.0000,2007-04-27-1-I
        45,2007-02-08,P,4600,4600,15.0000,2007-04-27-1-I
        46,2007-02-12,P,3500,3500,14.9100,2007-04-27-1-I
        47,2007-02-13,P,1500,1500,14.6500,2007-04-27-1-D
        48,2007-02-14,P,2000,2000,14.4900,2007-04-27-1-D
        49,2007-02-15,P,3000,3000,14.3000,2007-04-27-1-I
        50,2007-02-21,P,8500,8500,14.6500,2007-04-27-1-D
        51,2007-02-21,S,8500,8500,14.6500,2007-04-27-1-I
        52,2007-02-22,P,1500,1500,14.8800,2007-04-27-1-I
        53,2007-02-23,P,3000,3000,14.9700,2007-04-27-1-I
        54,2007-02-23,P,5000,5000,14.9700,2007-04-27-1-I
        55,2007-02-27,P,5200,5200,13.8800,2007-04-27-1-I
        56,2007-02-28,P,6700,6700,13.0000,2007-04-27-1-D
        57,2007-02-28,P,800,800,13.0000,2007-04-27-1-I
        58,2007-02-28,P,8400,8400,13.0000,2007-04-27-1-I
        59,2007-03-01,P,2500,2500,12.2500,2007-04-27-1-D
        60,2007-03-05,P,1800,1800,11.9700,2007-04-27-1-D
        61,2007-03-06,P,500,500,12.1300,2007-04-27-1-D
        62,2007-03-07,P,3000,3000,12.3700,2007-04-27-1-D
        63,2007-03-08,P,2000,2000,12.6000,2007-04-27-1-I
        64,2007-03-09,P,7700,7700,12.8100,2007-04-27-1-I
        65,2007-03-12,P,4200,4200,12.4600,2007-04-27-1-I
        66,2007-03-13,P,800,800,12.2500,2007-04-27-1-I
        67,2007-03-19,P,2000,2000,14.5500,2007-04-27-2-I
        68,2007-03-19,P,5000,5000,14.5500,2007-04-27-2-I
        69,2007-03-19,P,2000,2000,14.3300,2007-04-27-2-I
        70,2007-03-20,P,1000,1000,14.4600,2007-04-27-2-I
        71,2007-03-20,P,1500,1500,14.4600,2007-04-27-2-I
        72,2007-03-21,P,3900,3900,16.9000,2007-04-27-2-I
        73,2007-03-23,P,8000,8000,14.9700,2007-04-27-1-D
        74,2007-03-27,P,1000,1000,16.9300,2007-04-27-2-I
        75,2007-03-28,P,1000,1000,16.5000,2007-04-27-2-D
        76,2007-03-29,P,1000,1000,16.2500,2007-04-27-2-D
        77,2007-04-04,P,200,200,17.8600,2007-04-27-2-I
        78,2007-04-04,P,2000,2000,19.5000,2007-04-27-2-I
        79,2007-04-04,P,3000,3000,19.1300,2007-04-27-2-I
        80,2007-04-05,P,1000,1000,19.1500,2007-04-27-2-I
        81,2007-04-10,P,2000,2000,20.7500,2007-04-27-2-I
        82,2007-04-11,P,1000,1000,20.5000,2007-04-27-2-I
        83,2007-04-12,P,600,600,21.5000,2007-04-27-2-I
        84,2007-04-12,P,1000,1000,21.4500,2007-04-27-2-I
        85,2007-04-13,P,2100,2100,21.5000,2007-04-27-2-I
        86,2007-04-16,P,500,500,22.6000,2007-04-27-2-I
        87,2007-04-17,P,3500,3500,23.5500,2007-04-27-2-D
        88,2007-04-17,S,3500,3500,23.5500,2007-04-27-2-I
        89,2007-04-23,P,5000,5000,23.4500,2007-04-27-2-I
        90,2007-04-24,P,5000,5000,24.3000,2007-04-27-2-I
        91,2007-04-25,S,10000,10000,25.7000,2007-04-27-2-I
      CSV

      @org_file_body = <<~ORG

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

      @org_file_body_with_groups = <<~ORG

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

    describe 'construction' do
      it 'should be create-able from a CSV string' do
        tab = Table.from_csv_string(@csv_file_body)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 20
        expect(tab.headers.sort)
          .to eq %i[code date info price rawshares ref shares]
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

      it 'should be create-able from an Org string' do
        tab = Table.from_org_string(@org_file_body)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq %i[code date info price raw ref shares]
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

      it 'should be create-able from an Org string with groups' do
        tab = Table.from_org_string(@org_file_body)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.headers.sort)
          .to eq %i[code date info price raw ref shares]
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

      it 'should be create-able from a CSV file' do
        File.open('/tmp/junk.csv', 'w') { |f| f.write(@csv_file_body) }
        tab = Table.from_csv_file('/tmp/junk.csv')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 20
        expect(tab.headers.sort)
          .to eq %i[code date info price rawshares ref shares]
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
          expect(row[:info].class).to eq Date
        end
      end

      it 'should be create-able from an Org file' do
        File.open('/tmp/junk.org', 'w') { |f| f.write(@org_file_body) }
        tab = Table.from_org_file('/tmp/junk.org')
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to be > 10
        expect(tab.rows[0].keys.sort)
          .to eq %i[code date info price raw ref shares]
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

      it 'should create from an Array of Arrays with header and hrule' do
        # rubocop:disable Style/WordArray
        aoa = [
          ['First', 'Second', 'Third'],
          nil,
          ['1', '2', '3.2'],
          ['4', '5', '6.4'],
          ['7', '8', '9.0'],
          [10, 11, 12.1]
        ]
        tab = Table.from_aoa(aoa, hlines: true)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.groups.size).to eq(1)
        expect(tab.rows[0].keys.sort).to eq %i[first second third]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:first].is_a?(Numeric)).to be true
          expect(row[:second].is_a?(Numeric)).to be true
          expect(row[:third].is_a?(BigDecimal)).to be true
        end
      end

      it 'should create from an Array of Arrays with nil-marked header' do
        aoa = [
          ['First', 'Second', 'Third'],
          nil,
          ['1', '2', '3.2'],
          ['4', '5', '6.4'],
          ['7', '8', '9.0'],
          [10, 11, 12.1]
        ]
        tab = Table.from_aoa(aoa, hlines: true)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.groups.size).to eq(1)
        expect(tab.headers.sort).to eq %i[first second third]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:first].is_a?(Numeric)).to be true
          expect(row[:second].is_a?(Numeric)).to be true
          expect(row[:third].is_a?(BigDecimal)).to be true
        end
      end

      it 'should be create-able from an Array of Arrays sans Header' do
        aoa = [
          ['1', '2', '3.2'],
          ['4', '5', '6.4'],
          ['7', '8', '9.0'],
          [7, 8, 9.3]
        ]
        # rubocop:enable Style/WordArray

        # Set second param to true to say headers must be marked by an hline,
        # otherwise headers will be synthesized.
        tab = Table.from_aoa(aoa, hlines: true)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.headers.sort).to eq %i[col_1 col_2 col_3]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:col_1].is_a?(Numeric)).to be true
          expect(row[:col_2].is_a?(Numeric)).to be true
          expect(row[:col_3].is_a?(BigDecimal)).to be true
        end
      end

      it 'should be create-able from an Array of Hashes' do
        aoh = [
          { a: '1', 'Two words' => '2', c: '3.2' },
          { a: '4', 'Two words' => '5', c: '6.4' },
          { a: '7', 'Two words' => '8', c: '9.0' },
          { a: 10, 'Two words' => 11, c: 12.4 }
        ]
        tab = Table.from_aoh(aoh)
        expect(tab.class).to eq(Table)
        expect(tab.rows.size).to eq(4)
        expect(tab.rows[0].keys.sort).to eq %i[a c two_words]
        tab.rows.each do |row|
          row.each_pair do |k, _v|
            expect(k.class).to eq Symbol
          end
          expect(row[:a].is_a?(Numeric)).to be true
          expect(row[:two_words].is_a?(Numeric)).to be true
          expect(row[:c].is_a?(BigDecimal)).to be true
        end
      end

      it 'should be create-able from a SQL query', :db do
        user = ENV['TRAVIS'] == 'true' ? 'postgres' : ENV['LOGNAME']
        out_file = "#{__dir__}/../../tmp/psql.out"
        sql_file = "#{__dir__}/../../example_files/trades.sql"
        create_cmd =
          if ENV['TRAVIS'] == 'true'
            "psql -q -f #{sql_file} -U postgres >#{out_file} 2>&1"
          else
            "psql -q -f #{sql_file} >#{out_file} 2>&1"
          end
        ok = system(create_cmd)
        expect(ok).to be_truthy
        if ok
          FatTable.set_db(database: 'fat_table_spec',
                          host: 'localhost',
                          user: user)
          query = <<~SQL
            SELECT ref, date, code, price, shares
            FROM trades
            WHERE shares > 1000;
          SQL
          tab = Table.from_sql(query)
          expect(tab.class).to eq(Table)
          expect(tab.rows.size).to be > 100
        end
      end

      it 'add group boundaries on reading from org text' do
        tab = Table.from_org_string(@org_file_body_with_groups)
        expect(tab.groups.size).to eq(4)
        expect(tab.groups[0].size).to eq(1)
        expect(tab.groups[1].size).to eq(3)
        expect(tab.groups[2].size).to eq(7)
        expect(tab.groups[3].size).to eq(3)
      end

      it 'should set T F columns to Boolean' do
        cwd = File.dirname(__FILE__)
        dwtab = Table.from_org_file(cwd + '/../../example_files/datawatch.org')
        expect(dwtab.column(:g10).type).to eq('Boolean')
        expect(dwtab.column(:qp10).type).to eq('Boolean')
        dwo = dwtab.where('qp10 || g10')
        dwo.rows.each do |row|
          expect(row[:qp10].class.to_s).to match(/TrueClass|FalseClass/)
        end
      end
    end
  end
end
