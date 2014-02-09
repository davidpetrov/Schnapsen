require_relative 'constants.rb'
require_relative 'card.rb'
require_relative 'deck.rb'
require_relative 'player.rb'
require_relative 'computer.rb'
require_relative 'board.rb'
require_relative 'userinterface.rb'
require_relative 'main.rb'
module Schnapsen
  class Game
    def initialize
      @player_score = 0
      @computer_score = 0
      @last_winner = rand(2)
    end

    def check_for_winner
      if @player_score >= 11
        :player
      elsif @computer_score >= 11
        :computer
      else
        nil
      end
    end

    def score_update(result)
      if result.last == :player
        @player_score += result.first
        @last_winner = 0
      else
        @computer_score += result.first
        @last_winner = 1
      end
    end

    def play
      while check_for_winner.nil?
        gameset = GameSet.new(@last_winner)
        gameset.draw
        score_update(gameset.play(:open))
        puts "Score #{@player_score} : #{@computer_score}"
      end
    end
  end

  game = Game.new
  game.play
end