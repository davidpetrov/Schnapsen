require_relative 'constants.rb'
require_relative 'card.rb'
require_relative 'deck.rb'
class Player
  attr_accessor :hand, :points

  def initialize(name, hand, points = 0)
    @name = name
    @hand = Deck.new(hand)
    @points = points
  end

  def draw_card(card)
    @hand.add(card)
  end

  def pair_points(move, trump)
    pairs = {:Q => :K, :K => :Q}
    pair_card = Card.new(move.suit, pairs[move.value])
    if pairs.keys.include?(move.value) and @hand.include?(pair_card)
      move.suit == trump.suit ? 40 : 20
    else
      0
    end
  end

  def check_for_nine_of_trumps(trump)
    @hand.include?(Card.new(trump.suit, 9))
  end

  def valid_move?(trump, player_move, computer_move)
    same_suit_moves = @hand.select { |card| card.suit == computer_move.suit }
    take_moves = same_suit_moves.select { |card| Constants::VALUES[card.value] > Constants::VALUES[computer_move.value] }
    if !same_suit_moves.empty?
      if take_moves.empty?
        same_suit_moves.include?(player_move)
      else
        same_suit_moves.include?(player_move) and Constants::VALUES[player_move.value] > Constants::VALUES[computer_move.value]
      end
    else
      trump_list = @hand.select { |card| card.suit == trump.suit }
      trump_list.empty? ? true : trump_list.include?(player_move)
    end
  end
end