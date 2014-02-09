class Board
  attr_accessor :player_hand, :computer_hand, :state, :deck, :player_move, :computer_move, :trump
  def initialize  
  end

  def change_trump(card)
    @trump = card
    @deck.add(Card.new(@trump.suit, 9))
  end
end