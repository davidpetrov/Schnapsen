class Constants
  SUITS = { :spade => 4, :heart => 3 , :diamond => 2 , :club => 1 }
  VALUES = {:A => 11, 10 => 10, :K => 4, :Q => 3, :J => 2, 9 => 0 }

  def self.trump_set(suit)
    SUITS.each { |s, v| SUITS[s] = s == suit ? 4 : v - 1 }
  end
end