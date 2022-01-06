RSpec.describe FatTable do
  before :all do
    class B < FatTable::Table
      attr_accessor :extra
      def initialize(extra = "Default extra")
        @extra = extra
      end
    end

    it 'preserves instance variables when inherited' do
      str = <<-CSV.strip_heredoc
      Ref,Date,Code,RawShares,Shares,Price,Info
      1,5/2/2006,P,5000,5000,8.6000,2006-08-09-1-I
      2,05/03/2006,P,5000,5000,8.4200,2006-08-09-1-I
      3,5/4/2006,P,5000,5000,8.4000,2006-08-09-1-I
    CSV
      btab = B.from_csv_string(str)
      b.extra = "Special extra"
      btab = b.select(:ref, :date, :code, :shares, :price, cost: 'shares * price')
      expect(btab.extrs).to eq('Special extra')
    end
  end
end
