require_relative 'constants.rb'
require_relative 'card.rb'
require_relative 'deck.rb'
module Schnapsen
  class Computer
    attr_accessor :hand, :points, :possible_player_hand

    def initialize(hand, points = 0)
      @hand = Deck.new(hand)
      @points = points
      full_deck = Deck.full_deck   
      @possible_player_hand = full_deck.select { |card| !@hand.include?(card) }
    end

    def draw_card(card)
      @hand.add(card)
    end

    def check_for_nine_of_trumps(trump)
      @hand.include?(Card.new(trump.suit, 9))
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

    def find_pair(trump)
      queens = @hand.select { |card| card.value == :Q }
      paired_queens = queens.select { |queen| @hand.include?(Card.new(queen.suit, :K))}
      if paired_queens.empty?
        nil
      else
        paired_queens.map { |queen| [pair_points(queen, trump), queen] }.max.last
      end
    end

    def evaluate_hand(trump, state, on_move, player_move = nil)
      if state == :open
        if on_move == 1
          if find_pair(trump).nil?
            @hand.min_by { |card| card.suit == trump.suit ? Constants::VALUES[card.value] + 12 : Constants::VALUES[card.value] }
          else
            find_pair(trump)
          end
        else
          possible_take_moves = @hand.select do |card|
            card.suit == player_move.suit and card > player_move
          end
          if possible_take_moves.empty? and Constants::VALUES[player_move.value] >= 10
            trump_list = @hand.select { |card| card.suit == trump.suit }.min_by { |card| Constants::VALUES[card.value] }
          elsif possible_take_moves.empty?
            @hand.min_by { |card| card.suit == trump.suit ? Constants::VALUES[card.value] + 12 : Constants::VALUES[card.value] }
          else
            possible_take_moves.max
          end
        end
      elsif state == :closed or state == :final
        if on_move == 1
          @hand.max #to do improvements
        else
          same_suit_moves = @hand.select { |card| card.suit == player_move.suit }
          if !same_suit_moves.empty?
            take_moves = same_suit_moves.select { |card| Constants::VALUES[card.value] > Constants::VALUES[player_move.value] }
            take_moves.empty? ? same_suit_moves.min : same_suit_moves.max
          else
            if player_move.suit == trump.suit
              @hand.min
            else
              trump_list = @hand.select { |card| card.suit == trump.suit }
              trump_list.empty? ? @hand.min : trump_list.max
            end
          end
        end
      end
    end
  end
end