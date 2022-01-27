class Array
  # Map booleans true to 1 and false to 0 so they can be compared in a sort
  # with the <=> operator.
  def map_booleans
    map do |v|
      if v == true
        1
      elsif v == false
        0
      else
        v
      end
    end
  end

  def filter_to_type(typ)
    if typ == 'Boolean'
      compact.select { |i| i.is_a?(TrueClass) || i.is_a?(FalseClass) }
    elsif typ == 'DateTime'
      compact.select { |i| i.is_a?(Date) || i.is_a?(DateTime) || i.is_a?(Time) }
        .map { |i| i.to_datetime }
    elsif typ == 'Numeric'
      compact.select { |i| i.is_a?(Numeric) }
    elsif typ == 'String'
      map { |i| i.to_s }
    elsif typ == 'NilClass'
      self
    else
      raise ArgumentError, "cannot filter_to_type for type '#{typ}'"
    end
  end
end
