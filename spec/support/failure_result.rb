class FailureResult < Hashie::Mash
  def success?
    false
  end

  def executed?
    true
  end
end
