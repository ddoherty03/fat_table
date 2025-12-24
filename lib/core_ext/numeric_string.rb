# frozen_string_literal: true

require 'debug'

# This refinement contains methods that extend the String class to massage
# strings that represent numbers, such as adding commas, pre- and
# post-padding, etc.
module NumericString
  # You can control how NumericString behaves by supplying a new
  # NumericString::Config to the config: parameter of these methods.  Calling
  # `NumericString::Config.build` gives you the deafult configuration with
  # whatever overrides you give it.  You can also modify an existing config
  # with some overrides. For example:
  #
  # #+begin_src ruby
  #   cfg = NumericString::Config.build(group_size: 4)
  #   cfg2 = cfg.with(group_char: '_')
  #
  #   "1234567.89".add_grouping(config: cfg)
  #   => "123,4567.89"
  #   "1234567.89".add_grouping(config: cfg2)
  #   => '123_4567.89'
  # #+end_src
  Config = Struct.new(
    :group_char,
    :group_size,
    :decimal_char,
    :currency_symbol,
    :pre_pad_char,
    :post_pad_char,
    keyword_init: true,
  ) do
    DEFAULTS = {
      group_char: ',',
      group_size: 3,
      decimal_char: '.',
      currency_symbol: '$',
      pre_pad_char: '0',
      post_pad_char: '0',
    }.freeze

    def self.default
      @default ||= new(**DEFAULTS).freeze
    end

    # Build from defaults, overriding selectively
    def self.build(**overrides)
      new(**DEFAULTS.merge(overrides)).freeze
    end

    # Clone-with-changes (very Ruby, very nice)
    def with(**overrides)
      self.class.build(
        group_char:      overrides.fetch(:group_char, group_char),
        group_size:      overrides.fetch(:group_size, group_size),
        decimal_char:    overrides.fetch(:decimal_char, decimal_char),
        currency_symbol: overrides.fetch(:currency_symbol, currency_symbol),
        pre_pad_char: overrides.fetch(:pre_pad_char, pre_pad_char),
        post_pad_char: overrides.fetch(:post_pad_char, post_pad_char),
      )
    end
  end

  refine String do
    # If self is a valid decimal number, add grouping commas to the whole
    # part, retaining any fractional part and currency symbol undisturbed.
    # The optional cond: parameter can contain a test to determine if the
    # grouping ought to be performed.  If (1) self is not a valid decimal
    # number string, (2) the whole part already contains grouping characters,
    # or (3) cond: is falsey, return self.
    def add_grouping(cond: true, config: Config.default)
      return self unless cond
      return self unless valid_num?(config:)

      cur, whole, frac = cur_whole_frac(config:)
      return self if whole.include?(config.group_char)

      whole = whole.split('').reverse
                .each_slice(config.group_size).to_a
                .map { |a| a.reverse.join }
                .reverse
                .join(config.group_char)
      cur + whole + frac
    end

    alias_method :add_commas, :add_grouping

    # If self is a valid decimal number, add the currency symbol (per
    # NumericString::Config.currency_symbol) to the front of the number
    # string, retaining any grouping characters undisturbed.  The optional
    # cond: parameter can contain a test to determine if the currency symbol
    # ought to be pre-pended.  If (1) self is not a valid decimal number
    # string, (2) the currency symbol is already present, or (3) cond: is
    # falsey, return self.
    def add_currency(cond: true, config: Config.default)
      return self unless cond
      return self unless valid_num?(config:)

      md = match(num_re(config:))
      return self unless md[:cur].blank?

      config.currency_symbol + self
    end

    def add_pre_digits(n, cond: true, config: Config.default)
      return self unless cond
      return self if n <= 0
      return self unless valid_num?(config:)

      cur, whole, frac = cur_whole_frac(config:)
      n_pads = [n - whole.delete(config.group_char).size, 0].max
      padding = config.pre_pad_char * n_pads
      "#{cur}#{padding}#{whole}#{frac}"
    end

    def add_post_digits(n, cond: true, config: Config.default)
      return self unless cond
      return self unless valid_num?(config:)

      cur, whole, frac = cur_whole_frac(config:)
      frac_digs = frac.size - 1 # frac includes the decimal character
      if n >= frac_digs
        n_pads = [n - frac_digs, 0].max
        padding = config.post_pad_char * n_pads
        "#{cur}#{whole}#{frac}#{padding}"
      elsif n.zero?
        # Round up last digit of whole if first digit of frac >= 5
        if frac[1].to_i >= 5
          whole = whole[0..-2] + (whole[-1].to_i + 1).to_s
        end
        # No fractional part
        "#{cur}#{whole}"
      elsif n.negative?
        # This calls for rounding the whole part to nearest 10^n.abs and
        # dropping the frac part.
        ndigs_in_whole = whole.delete(config.group_char).size
        nplaces = [ndigs_in_whole - 1, n.abs].min
        # Replace the right-most nplaces digs with the pre-pad character.
        replace_count = 0
        new_whole = +''
        round_char = whole.delete(config.group_char)[-1]
        rounded = false
        whole.split('').reverse_each do |c|
          if c == config.group_char
            new_whole << c
          elsif replace_count < nplaces
            new_whole << config.pre_pad_char
            round_char = c
            replace_count += 1
          elsif !rounded
            new_whole <<
              if round_char.to_i >= 5
                (c.to_i + 1).to_s
              else
                c
              end
            rounded = true
          else
            new_whole << c
          end
        end
        "#{cur}#{new_whole.reverse}"
      else
        # We have to shorten the fractional part, which required rounding.
        last_frac_dig = frac[n]
        following_frac_dig = frac[n + 1]
        if following_frac_dig.to_i >= 5
          last_frac_dig = (last_frac_dig.to_i + 1).to_s
        end
        frac = frac[0..(n - 1)] + last_frac_dig
        padding = ''
        "#{cur}#{whole}#{frac}#{padding}"
      end
    end

    private

    def num_re(config: Config.default)
      cur_sym = Regexp.quote(config.currency_symbol)
      grp_char = Regexp.quote(config.group_char)
      dec_char = Regexp.quote(config.decimal_char)
      /\A(?<cur>#{cur_sym})?(?<whole>[0-9#{grp_char}]+)(?<frac>#{dec_char}[0-9]*)?\z/
    end

    # Return the currency, whole and fractional parts of a string with a possible
    # decimal point attached to the frac part if present.
    def cur_whole_frac(config: Config.default)
      match = match(num_re(config:))
      [match[:cur].to_s, match[:whole].to_s, match[:frac].to_s]
    end

    def valid_num?(config: Config.default)
      match?(num_re(config:))
    end
  end
end
