module ConnectionId
  def complete_id?(data)
    return false if data.size < 8
    return true
  end

  def extract_id(data)
    return data[0..7]        
  end

end