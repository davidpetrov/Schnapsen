require_relative 'constants.rb'
require_relative 'card.rb'
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
    if key.kind_of?(Integer)
      @deck[key]
    else
      nil
    end
  end

  def []=(key, value)
    if key.kind_of?(Integer)
      @deck[key] = value
    else
      nil
    end
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