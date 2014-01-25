SUITS = { :spade => 4, :heart => 3 , :diamond => 2 , :club => 1 }
VALUES = {:A =>11, 10 => 10, :K => 4, :Q => 3, :J => 2, 9 => 0 }
class Card
  attr_accessor :suit, :value
  include Comparable
  def initialize(suit, value)
    @suit = suit
    @value = value
  end

  def to_s
    unicode_symbols = {:spade => "♠", :heart => "♥", :diamond => "♦", :club => "♣"}
    "#{value}#{unicode_symbols[suit]}"
  end

  def <=>(other)
    if suit == other.suit
      VALUES[value] <=> VALUES[other.value]
    else
      SUITS[suit] <=> SUITS[other.suit] 
    end
  end

  def ==(other)
    suit == other.suit and value == other.value
  end

  alias eql? ==
end

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
    # unicode_symbols = {:spade => "♠", :heart => "♥", :diamond => "♦", :club => "♣"}
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

  def trump_set(suit)
    SUITS.each { |s, v| SUITS[s] = s == suit ? 4 : v - 1 }
  end
end

class Set
  attr_accessor :state
  def initialize()
    @full_deck = Deck.new([])
    SUITS.each do |s, _|
      VALUES.each do |v, _|
        @full_deck.add(Card.new(s,v))
      end
    end
    @state = :open
  end

  def draw
    @full_deck.shuffle
    player_cards, computer_cards = [], []
    2.times do
      3.times { player_cards << @full_deck.remove() }
      3.times { computer_cards << @full_deck.remove() }
    end
    @trump = @full_deck.remove()
    @face_down_cards = @full_deck.add(@trump)
    @player = Player.new(:player, player_cards)
    @player.hand.trump_set(@trump.suit)
    @computer = Computer.new(computer_cards)
  end

  def get_player_move
    puts "Enter the position [0..5] of the card you want to play: "
    position = gets.to_i
    unless (0..5).include?(position.to_i)
      puts "Invalid position\n"
      return get_player_move
    end
    sorted_hand = @player.hand.deck.sort
    sorted_indexes = {}
    sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
    @player_move = @player.hand.remove(sorted_indexes[position.to_i])
  end

  def get_computer_move
    puts computer_choice = @computer.evaluate_hand(@trump, :open, false, @player_move)
    position = @computer.hand.deck.index(computer_choice)
    sorted_hand = @computer.hand
    sorted_indexes = {}
    sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
    @computer_move = @computer.hand.remove(sorted_indexes[position.to_i])
  end

  def to_s
    output = ""
    output << "Computer:      #{@computer.hand}".ljust(40) + "#{@computer.points}\n"
    output << "-------------------------------------------------------\n\n"
    output << "[#{state}]".ljust(20) + "#{@computer_move}\n"
    output << "#{@trump}".ljust(20) + "#{@player_move}\n\n"
    output << "-------------------------------------------------------\n"
    output << "Player:        #{@player.hand}".ljust(40) + "#{@player.points}\n"
    # puts sorted_hand = @player.hand
    # sorted_indexes = {}
    # sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
    # output << @player.hand.reduce(" " * 15) do |string, x|
    #   string << "#{@player.hand.deck.index(x)}"
    #   sorted_indexes[@player.hand.deck.sort.index(x)].value == 10 ? string << "   " : string << "  "
    # end
    output << " " * 15 +  @player.hand.to_s.split(' ').to_a.map(&:length).zip(0.upto(5).to_a).map do |l, i|
      i.to_s.ljust(l + 1)
    end.join
    output
  end
end

class Player
  attr_accessor :hand, :points
  def initialize(name, hand, points = 0)
    @name = name
    @hand = Deck.new(hand)
    @points = points
  end
end

class Computer
  attr_accessor :hand, :points
  def initialize(hand, points = 0)
    @hand = Deck.new(hand)
    @points = points
  end

  def evaluate_hand(trump, state, on_move, player_move = nil)
    # puts player_move
    if state == :open
      if on_move
        @deck.min_by{ |card| VALUES[card.value] }
      else
        possible_take_moves = @hand.select do |card|
          card.suit == player_move.suit and card > player_move
        end
          if possible_take_moves.empty?
            possible_give_moves = @hand.select do |card|
              card.suit != trump.suit
            end.min_by{ |card| VALUES[card.value] }
          else
            possible_take_moves.max
          end
      end
    else
      if on_move

      else

      end
    end

  end
end

# a = Card.new(:spade, 10)
# # b = Card.new(:club, :A)
# c = Card.new(:diamond, :Q)

# # deck = Deck.new([a,b,c])
# # deck.add(Card.new(:spade, :A))
# # # deck.map {|x| x.suit = :diamond}
# # puts deck
# # # puts deck.sort
# # deck.shuffle
# # puts deck
# deck = Deck.new([])
# SUITS.each do |s,n|
#   VALUES.each do |v,n|
#     deck.add(Card.new(s,v))
#   end
# end
# puts deck
# # deck.shuffle
# # deck.trump_set(:diamond)
# # deck.remove(10)
# # a = Card.new(:spade, 9)
# # p deck.remove(a)
# # b = Card.new(:spade, 9)
# # p a.eql? b
# selected = deck.select { |card| card.suit == c.suit and VALUES[card.value] > VALUES[c.value] }
# puts selected

set = Set.new
set.draw
puts set
set.get_player_move
set.get_computer_move
puts set
