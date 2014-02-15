require_relative 'constants.rb'
require_relative 'card.rb'
module Schnapsen
  class Deck
    include Enumerable
    attr_accessor :size, :deck
    
    def initialize(cards)
      @size = cards.size
      @deck = cards
    end

    def each(&block)
      @deck.each(&block)
    end

    def to_s
      @deck.sort.reduce("") { |string, card| string << "#{card} " }
    end

    def add(card)
      @deck << card
    end

    def remove(card = 0)
      if card.class == Fixnum
        @deck.delete_at(card)
      else
        @deck.delete_at(@deck.index(card))
      end
    end

    def shuffle
      @deck.shuffle!
    end

    def empty?
      @deck.empty?
    end

    def [](key)
      @deck[key]
    end

    def []=(key, value)
      @deck[key] = value 
    end

    def self.full_deck
      full_deck = Deck.new([])
      Constants::SUITS.each do |s, _|
        Constants::VALUES.each do |v, _|
          full_deck.add(Card.new(s,v))
        end
      end
      full_deck
    end
  end
end