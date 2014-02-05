require 'tree'                 # Load the library
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

class Minimax
  attr_accessor :player_hand, :computer_hand, :trump, :computer_points, :player_points, :turn
  def initialize
    full_deck = Deck.new([])
    SUITS.each do |s, _|
      VALUES.each do |v, _|
        full_deck.add(Card.new(s,v))
      end
    end
    full_deck.shuffle
    player_cards, computer_cards = [], []
    2.times do
      3.times { player_cards << full_deck.remove() }
      3.times { computer_cards << full_deck.remove() }
    end
    @trump = full_deck.remove()
    @computer_hand = Deck.new(computer_cards)
    @player_hand = Deck.new(player_cards)
    @comuter_points = rand(66)
    @player_points = rand(66)
    @turn = rand(2)# 0 e player 
  end

  def valid_move?(move, played_move, played_by = 0)
    hand = played_by == 0 ? @computer_hand : player_hand
    same_suit_moves = hand.select { |card| card.suit == played_move.suit }
    take_moves = same_suit_moves.select { |card| VALUES[card.value] > VALUES[played_move.value] }
    if !same_suit_moves.empty?
      if take_moves.empty?
        same_suit_moves.include?(move)
      else
        same_suit_moves.include?(move) and VALUES[move.value] > VALUES[played_move.value]
      end
    else
      trump_list = hand.select { |card| card.suit == @trump.suit }
      trump_list.empty? ? true : trump_list.include?(move)
    end
  end

  def evaluate_move_winner(turn, player_move, computer_move)#1 if player win -1 else
    if computer_move.suit == player_move.suit
      player_move <=> computer_move
    else
      if trump.suit == computer_move.suit or trump.suit == player_move.suit
        trump.suit == player_move.suit ? 1 : -1
      else
        turn.zero? ? 1 : -1
      end
    end    
  end

 def check_for_set_winner(player_points, computer_points)
    if player_points >= 66
      if computer_points == 0
        [:player, 3]
      elsif computer_points < 33
        [:player, 2]
      else
        [:player, 1]
      end
    elsif computer_points >= 66
      if player_points == 0
        [:computer, 3]
      elsif computer_points < 33
        [:computer, 2]
      else
        [:computer, 1]
      end
    else
      nil
    end
  end

  def generate(start_node, player_hand, computer_hand, player_points, computer_points, evaluate, turn = 0)
    p_hand = Deck.new(player_hand.deck.map{ |x| x })
    c_hand = Deck.new(computer_hand.deck.map{ |x| x })
    hand = turn == 0 ? c_hand : p_hand
    root = start_node.content.class == Array ? start_node.content.first : start_node.content
    p_hand.include?(root) ? p_hand.remove(root) : c_hand.remove(root)
    if evaluate
      hand.each do |card|
        p_points = player_points
        c_points = computer_points
        if valid_move?(card, root, turn)
          outcome = evaluate_move_winner(turn, root, card)
          move_value = VALUES[root.value] + VALUES[card.value]
          if outcome == 1
            turn == 0 ? p_points += move_value : c_points += move_value
          else
            turn == 0 ? c_points += move_value : p_points += move_value
          end
          t = outcome == 1 ? 0 : 1
          set_winner = check_for_set_winner(p_points, c_points)
          on_move = t == 0 ? :pl :  :co
          if set_winner.nil?
            id = card.to_s + outcome.to_s + p_points.to_s + c_points.to_s + on_move.to_s
            start_node << Tree::TreeNode.new(id, [card, outcome, p_points, c_points])
            generate(start_node[id], p_hand, c_hand, p_points, c_points, !evaluate, t)         
          else
            start_node << Tree::TreeNode.new(card.to_s + outcome.to_s + set_winner.to_s + on_move.to_s, [card, outcome, set_winner])
          end
        end
      end
    else
      hand.each do |card| 
        t = turn.zero? ? 1 : 0
        on_move = t == 0 ? :pl :  :co
        start_node << Tree::TreeNode.new(card.to_s + on_move.to_s, [card])
        generate(start_node[card.to_s + on_move.to_s], p_hand, c_hand, player_points, computer_points, !evaluate, t)
      end
    end
  end
end


mm = Minimax.new
#hardcoded example
mm.trump = Card.new(:spade, :J)
mm.player_hand = Deck.new([Card.new(:spade, :A), Card.new(:spade, :K), Card.new(:spade, :Q), 
  Card.new(:spade, 9), Card.new(:club, :A), Card.new(:club, 10)])
mm.computer_hand = Deck.new([Card.new(:club, :J), Card.new(:spade, 10), Card.new(:diamond, :Q), 
  Card.new(:diamond, 9), Card.new(:heart, :A), Card.new(:heart, 10)])
mm.player_points = 18
mm.computer_points = 53

puts "trump #{mm.trump}"
puts mm.player_hand
puts mm.computer_hand
puts mm.player_points
puts mm.computer_points
tree = Tree::TreeNode.new(Card.new(:heart, :A).to_s, Card.new(:heart, :A))
mm.generate(tree, mm.player_hand, mm.computer_hand, mm.player_points, mm.computer_points, true, 1)

tree.print_tree
puts tree
