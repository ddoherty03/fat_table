module FatTable
  module Convert
    # Convert val to the type of key, a ruby class constant, such as Date,
    # Numeric, etc. If type is NilClass, the type is open, and a non-blank val
    # will attempt conversion to one of the allowed types, typing it as a String
    # if no other type is recognized. If the val is blank, and the type is nil,
    # the Column type remains open. If the val is nil or a blank and the type is
    # already determined, the val is set to nil, and should be filtered from any
    # Column computations. If the val is non-blank and the Column type
    # determined, raise an error if the val cannot be converted to the Column
    # type. Otherwise, returns the converted val as an object of the correct
    # class.
    def self.convert_to_type(val, type, tolerant: false)
      case type
      when 'NilClass'
        if val != false && val.blank?
          # Leave the type of the Column open. Unfortunately, false counts as
          # blank and we don't want it to. It should be classified as a boolean.
          new_val = nil
        else
          # Only non-blank values are allowed to set the type of the Column
          bool_val = convert_to_boolean(val)
          new_val =
            if bool_val.nil?
              convert_to_date_time(val) ||
                convert_to_numeric(val) ||
                convert_to_string(val)
            else
              bool_val
            end
        end
        new_val
      when 'Boolean'
        if val.is_a?(String) && val.blank? || val.nil?
          nil
        else
          new_val = convert_to_boolean(val)
          if new_val.nil?
            raise IncompatibleTypeError
          end
          new_val
        end
      when 'DateTime'
        if val.blank?
          nil
        else
          new_val = convert_to_date_time(val)
          if new_val.nil?
            raise IncompatibleTypeError
          end
          new_val
        end
      when 'Numeric'
        if val.blank?
          nil
        else
          new_val = convert_to_numeric(val)
          if new_val.nil?
            raise IncompatibleTypeError
          end
          new_val
        end
      when 'String'
        if val.nil?
          nil
        elsif tolerant
          # Allow String to upgrade to one of Numeric, DateTime, or Boolean if
          # possible.
          if (new_val = convert_to_numeric(val))
            new_val
          elsif (new_val = convert_to_date_time(val))
            new_val
          elsif (new_val = convert_to_boolean(val))
            new_val
          else
            new_val = convert_to_string(val)
          end
          new_val
        else
          new_val = convert_to_string(val)
          if new_val.nil?
            raise IncompatibleTypeError
          end
          new_val
        end
      else
        raise LogicError, "Mysteriously, column has unknown type '#{type}'"
      end
    end

    # Convert the val to a boolean if it looks like one, otherwise return nil.
    # Any boolean or a string of t, f, true, false, y, n, yes, or no, regardless
    # of case is assumed to be a boolean.
    def self.convert_to_boolean(val)
      return val if val.is_a?(TrueClass) || val.is_a?(FalseClass)
      val = val.to_s.clean
      return nil if val.blank?
      if val.match?(/\A(false|f|n|no)\z/i)
        false
      elsif val.match?(/\A(true|t|y|yes)\z/i)
        true
      end
    end

    ISO_DATE_RE = %r{(?<yr>\d\d\d\d)[-\/]
                (?<mo>\d\d?)[-\/]
                (?<dy>\d\d?)\s*
                (T?\s*\d\d:\d\d(:\d\d)?
                ([-+](\d\d?)(:\d\d?))?)?}x

    AMR_DATE_RE = %r{(?<dy>\d\d?)[-/](?<mo>\d\d?)[-/](?<yr>\d\d\d\d)\s*
                     (?<tm>T\d\d:\d\d:\d\d(\+\d\d:\d\d)?)?}x

    # A Date like 'Tue, 01 Nov 2016' or 'Tue 01 Nov 2016' or '01 Nov 2016'.
    # These are emitted by Postgresql, so it makes from_sql constructor
    # possible without special formatting of the dates.
    INV_DATE_RE = %r{((mon|tue|wed|thu|fri|sat|sun)[a-zA-z]*,?)?\s+  # looks like dow
    (?<dy>\d\d?)\s+  # one or two-digit day
    (?<mo_name>[jfmasondJFMASOND][A-Za-z]{2,})\s+  # looks like a month name
    (?<yr>\d\d\d\d) # and a 4-digit year
    }xi

    # Convert the val to a DateTime if it is either a DateTime, a Date, a Time, or a
    # String that can be parsed as a DateTime, otherwise return nil. It only
    # recognizes strings that contain a something like '2016-01-14' or '2/12/1985'
    # within them, otherwise DateTime.parse would treat many bare numbers as dates,
    # such as '2841381', which it would recognize as a valid date, but the user
    # probably does not intend it to be so treated.
    def self.convert_to_date_time(val)
      return val if val.is_a?(DateTime)
      return val if val.is_a?(Date)
      return val.to_datetime if val.is_a?(Time)

      begin
        str = val.to_s.clean
        return nil if str.blank?

        if str.match(ISO_DATE_RE)
          date = DateTime.parse(val)
        elsif str =~ AMR_DATE_RE
          date = DateTime.new(Regexp.last_match[:yr].to_i,
                              Regexp.last_match[:mo].to_i,
                              Regexp.last_match[:dy].to_i)
        elsif str =~ INV_DATE_RE
          mo = Date.mo_name_to_num(last_match[:mo_name])
          date = DateTime.new(Regexp.last_match[:yr].to_i, mo,
                              Regexp.last_match[:dy].to_i)
        else
          return nil
        end
        # val = val.to_date if
        date.seconds_since_midnight.zero? ? date.to_date : date
      rescue ArgumentError
        nil
      end
    end

    # Convert the val to a Numeric if is already a Numeric or is a String that
    # looks like one. Any Float is promoted to a BigDecimal. Otherwise return
    # nil.
    def self.convert_to_numeric(val)
      return BigDecimal(val, Float::DIG) if val.is_a?(Float)
      return val if val.is_a?(Numeric)
      # Eliminate any commas, $'s (or other currency symbol), or _'s.
      cursym = Regexp.quote(FatTable.currency_symbol)
      clean_re = /[,_#{cursym}]/
      val = val.to_s.clean.gsub(clean_re, '')
      return nil if val.blank?
      case val
      when /(\A[-+]?\d+\.\d*\z)|(\A[-+]?\d*\.\d+\z)/
        BigDecimal(val.to_s.clean)
      when /\A[-+]?[\d]+\z/
        val.to_i
      when %r{\A(?<nm>[-+]?\d+)\s*[:/]\s*(?<dn>[-+]?\d+)\z}
        Rational(Regexp.last_match[:nm], Regexp.last_match[:dn])
      end
    end

    def self.convert_to_string(val)
      val.to_s
    end
  end
end
