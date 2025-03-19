module FatTable
  RSpec.describe Table do
    before do
      b_class = Class.new(FatTable::Table) do
        attr_accessor :extra

        def initialize(*heads, **types)
          super
        end
      end
      stub_const('B', b_class)
    end

    it 'preserves instance variables when inherited' do
      str = <<-CSV.strip_heredoc
      Ref,Date,Code,RawShares,Shares,Price,Info
      1,5/2/2006,P,5000,5000,8.6000,2006-08-09-1-I
      2,05/03/2006,P,5000,5000,8.4200,2006-08-09-1-I
      3,5/4/2006,P,5000,5000,8.4000,2006-08-09-1-I
      CSV
      FatTable::Table.from_csv_string(str)
      btab = B.from_csv_string(str)
      btab.extra = "Special extra"
      btab = btab.select(:ref, :date, :code, :shares, :price, cost: 'shares * price')
      expect(btab.extra).to eq('Special extra')
    end
  end
end
