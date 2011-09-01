class Array
  def random
    self[rand(self.size)]
  end
end

class Hash
  def first
    self[self.keys.first]
  end
end
