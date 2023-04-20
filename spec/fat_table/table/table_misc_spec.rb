module FatTable
  RSpec.describe Table do
    describe 'problematic examples' do
      it 'works the zip example from README' do
        tab = FatTable.new(:a, 'b', 'C', :d, :zip, zip: '~')
        tab << { a: 1, b: 2, c: "<2017-01-21>", d: 'f', e: '', zip: 18552 }
        tab << { a: 3.14, b: 2.17, c: '[2016-01-21 Thu]', d: 'Y', e: nil }
        tab << { zip: '01879-7884' }
        tab << { zip: '66210' }
        tab << { zip: '90210' }
      end
    end
  end
end
