module FatTable
  using NumericString

  RSpec.describe 'NumericString' do
    describe 'add_grouping' do
      describe 'add_grouping alias add_commas' do
        it 'adds commas to a whole number' do
          expect('1234567899'.add_grouping).to eq('1,234,567,899')
          expect('1234567899'.add_commas).to eq('1,234,567,899')
        end

        it 'does nothing if commas already present' do
          expect('1,234,567,899'.add_commas).to eq('1,234,567,899')
        end

        it 'does nothing if cond: is falsey' do
          expect('1234567899'.add_commas(cond: 2 == 4)).to eq('1234567899')
        end

        it 'adds commas to a number with fractional part' do
          expect('1234567.899'.add_commas).to eq('1,234,567.899')
          expect('1234567.'.add_commas).to eq('1,234,567.')
        end

        it 'retains currency symbol if present' do
          expect('$1234567.899'.add_commas).to eq('$1,234,567.899')
          expect('$1,234,567,899'.add_commas).to eq('$1,234,567,899')
          expect('$1234567.899'.add_commas).to eq('$1,234,567.899')
        end

        it 'does nothing if number too small for commas' do
          expect('3.14159'.add_commas).to eq('3.14159')
        end

        it 'does nothing if not a number' do
          expect('3 for all'.add_commas).to eq('3 for all')
        end

        it 'does nothing if not a decimal number' do
          expect('AB987EF'.add_commas).to eq('AB987EF')
        end
      end

      describe 'add_grouping alias add_commas with Config' do
        it 'adds commas to a whole number' do
          cfg = NumericString::Config.build(group_char: '_')
          expect('1234567899'.add_grouping(config: cfg)).to eq('1_234_567_899')
          expect('1234567899'.add_commas(config: cfg)).to eq('1_234_567_899')
          cfg = NumericString::Config.build(group_char: '_', group_size: 4)
          expect('1234567899'.add_grouping(config: cfg)).to eq('12_3456_7899')
          expect('1234567899'.add_commas(config: cfg)).to eq('12_3456_7899')
        end

        it 'does nothing if commas already present' do
          expect('1,234,567,899'.add_commas).to eq('1,234,567,899')
        end

        it 'does nothing if cond: is falsey' do
          expect('1234567899'.add_commas(cond: 2 == 4)).to eq('1234567899')
        end

        it 'adds commas to a number with fractional part' do
          cfg = NumericString::Config.build(group_char: '.', group_size: 4, decimal_char: ',')
          expect('1234567,899'.add_commas(config: cfg)).to eq('123.4567,899')
          expect('1234567,'.add_commas(config: cfg)).to eq('123.4567,')
        end

        it 'retains currency symbol if present' do
          cfg = NumericString::Config.build(
            group_char: '.',
            group_size: 4,
            decimal_char: ',',
            currency_symbol: '€',
          )
          expect('€1234567,899'.add_commas(config: cfg)).to eq('€123.4567,899')
          expect('€1.234.567.899'.add_commas(config: cfg)).to eq('€1.234.567.899')
          expect('€1234567,899'.add_commas(config: cfg)).to eq('€123.4567,899')
        end
      end
    end

    describe 'add_currency' do
      it 'adds default currency symbol to number' do
        expect('66548.88'.add_currency).to eq('$66548.88')
        expect('66548'.add_currency).to eq('$66548')
      end

      it 'does not disturb grouping chars if present' do
        expect('66,548.88'.add_currency).to eq('$66,548.88')
        expect('66,548'.add_currency).to eq('$66,548')
      end

      it 'does not disturb leading pre-digits if present' do
        expect('000066548.88'.add_currency).to eq('$000066548.88')
        expect('000,066,548'.add_currency).to eq('$000,066,548')
        jp_cfg = NumericString::Config.build(currency_symbol: '¥')
        expect('000,066,548'.add_currency(config: jp_cfg)).to eq('¥000,066,548')
      end

      it 'does not disturb trailing post-digits if present' do
        expect('66548.880000'.add_currency).to eq('$66548.880000')
        jp_cfg = NumericString::Config.build(currency_symbol: '¥')
        expect('66,548.76800'.add_currency(config: jp_cfg)).to eq('¥66,548.76800')
      end

      it 'does not add currency symbol if already present' do
        expect('$66548.88'.add_currency).to eq('$66548.88')
        expect('$66548'.add_currency).to eq('$66548')
        # The following only works because it is not considered a valid number
        # under the default configuration.
        expect('€66548'.add_currency).to eq('€66548')
      end

      it 'adds a configured currency symbol to number' do
        jp_cfg = NumericString::Config.build(currency_symbol: '¥')
        expect('66548.88'.add_currency(config: jp_cfg)).to eq('¥66548.88')
      end

      it 'does not add a configured currency symbol if present' do
        jp_cfg = NumericString::Config.build(currency_symbol: '¥')
        expect('¥66548.88'.add_currency(config: jp_cfg)).to eq('¥66548.88')
      end

      it 'has no affect on a non-number' do
        expect('hello, world'.add_currency).to eq('hello, world')
      end

      it 'does nothing if cond falsey' do
        expect('45,862.11'.add_currency(cond: 2 + 2 == 5)).to eq('45,862.11')
      end
    end

    describe 'add_pre_digits' do
      it 'adds the specified pre-digits to a number' do
        expect('45862.11'.add_pre_digits(7)).to eq('0045862.11')
      end

      it 'adds nothing if number is longer than pad size' do
        expect('45862.11'.add_pre_digits(4)).to eq('45862.11')
      end

      it 'does not disturb existing group chars' do
        expect('45,862.11'.add_pre_digits(10)).to eq('0000045,862.11')
      end

      it 'does nothing if cond falsey' do
        expect('45,862.11'.add_pre_digits(10, cond: 2 + 2 == 5)).to eq('45,862.11')
      end

      it 'does nothing if n digits less or equal to zero' do
        expect('45,862.11'.add_pre_digits(0)).to eq('45,862.11')
        expect('45,862.11'.add_pre_digits(-10)).to eq('45,862.11')
      end

      it 'allows the padding char to be configured' do
        cfg = NumericString::Config.build(pre_pad_char: 'X')
        expect('45,862.11'.add_pre_digits(10, config: cfg)).to eq('XXXXX45,862.11')
      end
    end

    describe 'add_post_digits' do
      it 'adds the specified post-digits to a number' do
        expect('45862.11'.add_post_digits(7)).to eq('45862.1100000')
      end

      it 'adds nothing if number is longer than pad size' do
        expect('45862.118654'.add_post_digits(4)).to eq('45862.118654')
      end

      it 'does not disturb existing group chars' do
        expect('45,862.11'.add_post_digits(10)).to eq('45,862.1100000000')
      end

      it 'does nothing if cond falsey' do
        expect('45,862.11'.add_post_digits(10, cond: 2 + 2 == 5)).to eq('45,862.11')
      end

      it 'does nothing if n digits less or equal to zero' do
        expect('45,862.11'.add_post_digits(0)).to eq('45,862.11')
        expect('45,862.11'.add_post_digits(-10)).to eq('45,862.11')
      end

      it 'allows the padding char to be configured' do
        cfg = NumericString::Config.build(post_pad_char: 'X')
        expect('45,862.11'.add_post_digits(10, config: cfg)).to eq('45,862.11XXXXXXXX')
      end
    end

    describe 'chaining methods' do
      it 'chains grouping, pre-digits, currency, and post-digits' do
        expect('45862.11'.add_grouping
                 .add_post_digits(7)
                 .add_pre_digits(8)
                 .add_currency).to eq('$00045,862.1100000')
      end

      it 'order matters: chains pre-digits, currency, and post-digits, and grouping' do
        expect('45862.11'.add_post_digits(7)
                 .add_pre_digits(8)
                 .add_currency
                 .add_grouping).to eq('$00,045,862.1100000')
      end
    end
  end
end
