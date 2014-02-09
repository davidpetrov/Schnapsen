require_relative 'constants.rb'
require_relative 'card.rb'
require_relative 'deck.rb'
require_relative 'player.rb'
require_relative 'computer.rb'
require_relative 'board.rb'
require_relative 'userinterface.rb'
module Schnapsen
  class GameSet
    attr_accessor :user_interface

    def initialize(turn = rand(2))
      @board = ::Schnapsen::Board.new
      @board.deck = Deck.full_deck
      @board.state = :open
      @turn = turn
      @user_interface = UserInterface.new(@board)
    end

    def draw
      @board.deck.shuffle
      player_cards, computer_cards = [], []
      2.times do
        3.times { player_cards << @board.deck.remove }
        3.times { computer_cards << @board.deck.remove }
      end
      @board.change_trump(@board.deck.remove)
      Constants.trump_set(@board.trump.suit)
      @board.deck.add(@board.trump)
      @player = Player.new(:player, player_cards)
      @computer = Computer.new(computer_cards)
    end

    def exchange_nine_of_trumps(player)
      nine_of_trumps = Card.new(@board.trump.suit, 9)
      player.hand.add(@board.trump)
      player.hand.remove(nine_of_trumps)
      @board.change_trump(nine_of_trumps)
    end

    def score_calculate
      winner = check_for_gameset_winner
      loser = winner == :player ? @computer : @player
      if loser.points == 0
        [3, winner]
      elsif loser.points < 33
        [2, winner]
      else
        [1, winner]
      end
    end

    def check_for_gameset_winner
      if @player.points >= 66
        :player
      elsif @computer.points >= 66
        :computer
      else
        nil
      end
    end

    def play_player_turn(round)
      display_board
      if @player.check_for_nine_of_trumps(@board.trump) and round.between?(2, 5)
        @user_interface.exchange_9_prompt
        if @user_interface.answer
          exchange_nine_of_trumps(@player)
          display_board
        end
      end
      if @board.state == :open and round.between?(2, 5)
        @user_interface.closed_state_prompt
        if @user_interface.answer
          @board.state = :closed
          display_board
        end
      end
      get_player_move
      @player.points += @player.pair_points(@board.player_move, @board.trump)
      display_board
      return score_calculate if !check_for_gameset_winner.nil?
      @computer.possible_player_hand.delete(@board.player_move)
      get_computer_move
      points_update
      return score_calculate if !check_for_gameset_winner.nil?
      turn_update
      if @board.state == :open and !@board.deck.empty?
        @player.draw_card(@board.deck.remove())
        card_drawn = @board.deck.remove()
        @computer.draw_card(card_drawn)
        @computer.possible_player_hand.delete(card_drawn)
      end
      display_board
    end

    def play_computer_turn(round)
      if @computer.check_for_nine_of_trumps(@board.trump) and round.between?(2, 5)
        exchange_nine_of_trumps(@computer)
      end
      get_computer_move
      @computer.points += @computer.pair_points(@board.computer_move, @board.trump)
      display_board
      return score_calculate if !check_for_gameset_winner.nil?
      get_player_move_with_validation(@board.state)
      @computer.possible_player_hand.delete(@board.player_move)
      points_update
      return score_calculate if !check_for_gameset_winner.nil?
      turn_update
      if @board.state == :open and !@board.deck.empty?
        card_drawn = @board.deck.remove()
        @computer.draw_card(card_drawn)
        @computer.possible_player_hand.delete(card_drawn)
        @player.draw_card(@board.deck.remove())
      end
      display_board
    end

    def display_board
      @user_interface.display_board(@player.points, @computer.points, @player.hand, @computer.hand)
    end

    def move(round)
      if @turn.zero?
        play_player_turn(round)
      else
        play_computer_turn(round)
      end
    end

    def play(state)
      1.upto(12) do |round|
        if @board.state == :open and round > 6
          @board.state = :final
        end 
        puts "round #{round}"
        result = move(round)
        if !result.nil?
          # puts result
          # break
          return result
        end
        @board.player_move = nil
        @board.computer_move = nil
      end
    end


    def evaluate_move_winner(turn)#1 if player win -1 else
      if @board.computer_move.suit == @board.player_move.suit
        @board.player_move <=> @board.computer_move
      else
        if @board.trump.suit == @board.computer_move.suit or @board.trump.suit == @board.player_move.suit
          @board.trump.suit == @board.player_move.suit ? 1 : -1
        else
          turn.zero? ? 1 : -1
        end
      end    
    end

    def points_update
      move_value = Constants::VALUES[@board.player_move.value] + Constants::VALUES[@board.computer_move.value]
      evaluate_move_winner(@turn) > 0 ? @player.points += move_value : @computer.points += move_value
    end

    def turn_update
      @turn = evaluate_move_winner(@turn) > 0 ? 0 : 1
    end

    def get_player_move
      @user_interface.choose_card_prompt
      position = gets.to_i
      unless (0..5).include?(position.to_i)
        @user_interface.invalid_position_prompt
        return get_player_move
      end
      sorted_hand = @player.hand.deck.sort
      sorted_indexes = {}
      sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
      @board.player_move = @player.hand.remove(sorted_indexes[position.to_i])
    end

    def get_player_move_with_validation(state)
      @user_interface.choose_card_prompt
      position = gets.to_i
      unless (0..5).include?(position.to_i)
        @user_interface.invalid_position_prompt
        return get_player_move_with_validation(state)
      end
      sorted_hand = @player.hand.deck.sort
      sorted_indexes = {}
      sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
      if state == :closed or state == :final
        if !@player.valid_move?(@board.trump, sorted_indexes[position.to_i], @board.computer_move)
          @user_interface.invalid_position_prompt
          return get_player_move_with_validation(state)
        end
      end
      @board.player_move = @player.hand.remove(sorted_indexes[position.to_i])
    end

    def get_computer_move
      computer_choice = @computer.evaluate_hand(@board.trump, @board.state, @turn, @board.player_move)
      position = @computer.hand.deck.index(computer_choice)
      sorted_hand = @computer.hand
      sorted_indexes = {}
      sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
      @board.computer_move = @computer.hand.remove(sorted_indexes[position.to_i])
    end
  end
end

# gameset = GameSet.new
# gameset.draw
# gameset.play(:open)