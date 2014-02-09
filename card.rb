require_relative 'constants.rb'
module Schnapsen
  class Card
    include Comparable
    attr_accessor :suit, :value

    def initialize(suit, value)
      @suit = suit
      @value = value
    end

    def to_s
      unicode_symbols = {:spade => "♠", :heart => "♥", :diamond => "♦", :club => "♣"}
      "#{@value}#{unicode_symbols[@suit]}"
    end

    alias eql? ==

    def hash
      [@suit, @value].hash
    end

    def <=>(other)
      if suit == other.suit
        Constants::VALUES[value] <=> Constants::VALUES[other.value]
      else
        Constants::SUITS[suit] <=> Constants::SUITS[other.suit] 
      end
    end
  end
end