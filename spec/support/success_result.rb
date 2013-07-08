class SuccessResult < Hashie::Mash
  def success?
    true
  end

  def executed?
    true
  end
end
