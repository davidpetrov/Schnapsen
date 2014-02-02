SUITS = { :spade => 4, :heart => 3 , :diamond => 2 , :club => 1 }
VALUES = {:A => 11, 10 => 10, :K => 4, :Q => 3, :J => 2, 9 => 0 }
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
    @turn = rand(2)
  end

  def trump_set(suit)
    SUITS.each { |s, v| SUITS[s] = s == suit ? 4 : v - 1 }
  end

  def draw
    @full_deck.shuffle
    player_cards, computer_cards = [], []
    2.times do
      3.times { player_cards << @full_deck.remove() }
      3.times { computer_cards << @full_deck.remove() }
    end
    @trump = @full_deck.remove()
    trump_set(@trump.suit)
    @full_deck.add(@trump)
    @player = Player.new(:player, player_cards)
    @computer = Computer.new(computer_cards)
  end

  def exchange_nine_of_trumps(player)
    nine_of_trumps = Card.new(@trump.suit, 9)
    @full_deck.remove(@trump)
    player.hand.add(@trump)
    player.hand.remove(nine_of_trumps)
    @full_deck.add(nine_of_trumps)
    @trump = nine_of_trumps
  end

  def move(round)
    if @turn.zero?
      puts self
      if @player.check_for_nine_of_trumps(@trump) and round.between?(2, 5)
        puts "Do you want to exchange 9 of trups? [y, n]\n"
        answer = gets
        if answer.to_s.match(/y/)
          exchange_nine_of_trumps(@player)
          puts self
        end
      end
      get_player_move
      @player.points += @player.pair_points(@player_move, @trump)
      puts self
      get_computer_move
      score_update
      turn_update
      if @state == :open and !@full_deck.empty?
        @player.draw_card(@full_deck.remove())
        @computer.draw_card(@full_deck.remove())
      end
      puts self
    else
      if @computer.check_for_nine_of_trumps(@trump) and round.between?(2, 5)
        exchange_nine_of_trumps(@computer)
      end
      get_computer_move
      @computer.points += @computer.pair_points(@computer_move, @trump)
      puts self
      get_player_move
      score_update
      turn_update
      if @state == :open and !@full_deck.empty?
        @computer.draw_card(@full_deck.remove())
        @player.draw_card(@full_deck.remove())
      end
      puts self
    end
  end

  def moves(state)
    1.upto(12) do |round|
      @state = :closed if round > 6
      puts "round #{round}"
      move(round)
      if @computer.points >= 66
        puts "Computer wins\n"
        break
      elsif @player.points >= 66
        puts "Player wins\n"
        break
      elsif round == 12
        if evaluate_move_winner(@turn) == 1
          @player.points += 11
          puts "Player wins\n"
        else
          @computer.points += 11
          puts "Computer wins\n"
        end
      else
        @player_move = nil
        @computer_move = nil
      end
    end
  end


  def evaluate_move_winner(turn)#1 if player win 0 else
    if @computer_move.suit == @player_move.suit
      @player_move <=> @computer_move
    else
      if @trump.suit == @computer_move.suit or @trump.suit == @player_move.suit
        @trump.suit == @player_move.suit ? 1 : -1
      else
        turn.zero? ? 1 : -1
      end
    end    
  end

  def score_update
    move_value = VALUES[@player_move.value] + VALUES[@computer_move.value]
    evaluate_move_winner(@turn) > 0 ? @player.points += move_value : @computer.points += move_value
  end

  def turn_update
    @turn = evaluate_move_winner(@turn) > 0 ? 0 : 1
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
    computer_choice = @computer.evaluate_hand(@trump, :open, @turn, @player_move)
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
    output << "#{@full_deck[-1]}".ljust(20) + "#{@player_move}\n\n"
    output << "-------------------------------------------------------\n"
    output << "Player:        #{@player.hand}".ljust(40) + "#{@player.points}\n"
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
end

class Computer
  attr_accessor :hand, :points
  def initialize(hand, points = 0)
    @hand = Deck.new(hand)
    @points = points
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
          @hand.min_by { |card| card.suit == trump.suit ? VALUES[card.value] + 12 : VALUES[card.value] }
        else
          find_pair(trump)
        end
      else
        possible_take_moves = @hand.select do |card|
          card.suit == player_move.suit and card > player_move
        end
        if possible_take_moves.empty? and VALUES[player_move.value] >= 10
          trump_list = @hand.select { |card| card.suit == trump.suit }.min_by { |card| VALUES[card.value] }
        elsif possible_take_moves.empty?
          @hand.min_by { |card| card.suit == trump.suit ? VALUES[card.value] + 12 : VALUES[card.value] }
        else
          possible_take_moves.max
        end
      end
    else
      if on_move == 1

      else

      end
    end

  end
end

# class Board
#   def initialize(trump, state, on_move, computer_hand, player_hand, computer_move, player_move, computer_points, player_points)
#     output = ""
#     output << "Computer:      #{computer.hand}".ljust(40) + "#{computer.points}\n"
#     output << "-------------------------------------------------------\n\n"
#     output << "[#{state}]".ljust(20) + "#{computer_move}\n"
#     output << "#{@trump}".ljust(20) + "#{player_move}\n\n"
#     output << "-------------------------------------------------------\n"
#     output << "Player:        #{player.hand}".ljust(40) + "#{player.points}\n"
#     output << " " * 15 +  player.hand.to_s.split(' ').to_a.map(&:length).zip(0.upto(5).to_a).map do |l, i|
#       i.to_s.ljust(l + 1)
#     end.join
#     output
#   end
# end


# a = Card.new(:spade, 10)
# b = Card.new(:club, :A)
# c = Card.new(:diamond, :Q)

# deck = Deck.new([a,b,c])
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
set.moves(:open)
# p Deck.new([]).methods



