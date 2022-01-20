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
end
