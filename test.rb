require 'tree'   
require 'set'              # Load the library
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
    "#{@value}#{unicode_symbols[@suit]}"
  end

  alias eql? ==

  def hash
    [@suit,  @value].hash
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

  def valid_move?(move, played_move, played_by, player_hand, computer_hand)
    hand = played_by == 0 ? computer_hand : player_hand
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

  def check_for_winner(player_points, computer_points)
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
      elsif player_points < 33
        [:computer, 2]
      else
        [:computer, 1]
      end
    else
      nil
    end
  end

  def pair_points(move, hand)
    pairs = {:Q => :K, :K => :Q}
    pair_card = Card.new(move.suit, pairs[move.value])
    if pairs.keys.include?(move.value) and hand.include?(pair_card)
      move.suit == @trump.suit ? 40 : 20
    else
      0
    end
  end

  def generate(start_node, player_hand, computer_hand, player_points, computer_points, evaluate, turn)
    p_hand = Deck.new(player_hand.deck.map { |x| x })
    c_hand = Deck.new(computer_hand.deck.map { |x| x })
    hand = turn.zero? ? c_hand : p_hand
    root = start_node.content.class == Array ? start_node.content.first : start_node.content
    root_hand = p_hand.include?(root) ? 0 : 1
    p_hand.include?(root) ? p_hand.remove(root) : c_hand.remove(root)
    if root_hand == turn
      pair_points = root_hand.zero? ? pair_points(root, p_hand) : pair_points(root, c_hand)
      if root_hand.zero?
        winner = check_for_winner(player_points + pair_points, computer_points)
      else
        winner = check_for_winner(player_points, computer_points + pair_points)
      end
    else
      winner = nil
    end
    if !winner.nil?
      id = "pair " + "#{pair_points}" + winner.to_s + turn.to_s
      start_node << Tree::TreeNode.new(id, [pair_points, winner, turn])
    elsif evaluate
      hand.each do |card|
        new_player_points = player_points
        new_computer_points = computer_points
        last_eleven = hand.size == 1 ? 11 : 0
        if valid_move?(card, root, turn, p_hand, c_hand)
          outcome = turn.zero? ? evaluate_move_winner(turn, root, card) : evaluate_move_winner(turn, card, root)
          move_value = VALUES[root.value] + VALUES[card.value] + last_eleven
          outcome == 1 ? new_player_points += move_value : new_computer_points += move_value
          next_turn = outcome == 1 ? 1 : 0
          winner = check_for_winner(new_player_points, new_computer_points)
          played_by = root_hand.zero? ? 1 : 0 
          if winner.nil?
            id = card.to_s + new_player_points.to_s + new_computer_points.to_s + played_by.to_s
            start_node << Tree::TreeNode.new(id, [card, new_player_points, new_computer_points, played_by])
            generate(start_node[id], p_hand, c_hand, new_player_points, new_computer_points, !evaluate, next_turn)         
          else
            id = card.to_s + winner.to_s + played_by.to_s
            start_node << Tree::TreeNode.new(id, [card, winner, played_by])
          end
        end
      end
    else
      hand.each do |card| 
        next_turn = turn.zero? ? 1 : 0
        id = card.to_s + next_turn.to_s
        start_node << Tree::TreeNode.new(id, [card, player_points, computer_points, next_turn])
        generate(start_node[id], p_hand, c_hand, player_points, computer_points, !evaluate, next_turn)
      end
    end
  end

  def compare_scores(content, other)
    content <=> other
  end

  def compare_end_states(state, other)
    order = [[:player, 3], [:player, 2], [:player, 1], [:computer, 1], [:computer, 2], [:computer, 3]]
    order.index(state) <=> order.index(other)
  end

  def compare_score_and_state(score, state)
    state.first == :player ? 1 : -1
  end

  def compare_nodes(node, other)
    if node.length == 3 and other.length == 3
      compare_end_states(node[1], other[1])
    elsif node.length == 4 and other.length == 4
      compare_scores(node[2], other[2])
    elsif node.length == 4 and other.length ==3
      compare_score_and_state(node[2], other[1])
    else
      compare_score_and_state(other[1], node[2]) * (-1)
    end
  end

  def minimax(node)
    if node.children.empty?
      return node
    end
    if node.content.last == 1 or node.content.class == Card
      best_value = Tree::TreeNode.new("min", [nil, [:player, 3], nil])
      node.children.each do |child|
        value = minimax(child) 
        # puts value.content
        # puts best_value.content
        best_value = compare_nodes(value.content, best_value.content) == 1 ? value : best_value
        # puts "max #{best_value}"
      end
      return  best_value
    else
      best_value = Tree::TreeNode.new("max", [nil, [:computer, 3], nil])
      node.children.each do |child|
        value = minimax(child)
        # puts value.content
        # puts best_value.content
        best_value = compare_nodes(value.content, best_value.content) == -1 ? value : best_value
        # puts "min #{best_value.content}"
      end
      return best_value
    end
  end
end


mm = Minimax.new
#hardcoded example
# mm.trump = Card.new(:spade, :J)
# mm.player_hand = Deck.new([Card.new(:spade, :A), Card.new(:spade, :K), Card.new(:spade, :Q), 
#   Card.new(:spade, 9), Card.new(:club, :A), Card.new(:club, 10)])
# mm.computer_hand = Deck.new([Card.new(:club, :J), Card.new(:spade, 10), Card.new(:diamond, :Q), 
#   Card.new(:diamond, 9), Card.new(:heart, :A), Card.new(:heart, 10)])
# mm.player_points = 18
# mm.computer_points = 53

# mm.player_hand = Deck.new([Card.new(:spade, :A), Card.new(:spade, :Q)])
# mm.computer_hand = Deck.new([Card.new(:spade, :K), Card.new(:spade, 10)])
# mm.player_points = 50
# mm.computer_points = 50

mm.trump = Card.new(:spade, :J)
mm.computer_hand = Deck.new([Card.new(:spade, :A), Card.new(:spade, :K), Card.new(:spade, :Q), 
  Card.new(:spade, 9), Card.new(:club, :A), Card.new(:club, 10)])
mm.player_hand = Deck.new([Card.new(:club, :J), Card.new(:spade, 10), Card.new(:diamond, :Q), 
  Card.new(:diamond, 9), Card.new(:heart, :A), Card.new(:heart, 10)])
mm.player_points = 53
mm.computer_points = 18



puts "trump #{mm.trump}"
puts mm.player_hand
puts mm.computer_hand
puts mm.player_points
puts mm.computer_points
 # tree = Tree::TreeNode.new(Card.new(:heart, :A).to_s, Card.new(:heart, :A))
# tree = Tree::TreeNode.new(Card.new(:spade, :A).to_s, [Card.new(:spade, :A),1])
tree = Tree::TreeNode.new(Card.new(:heart, :A).to_s, [Card.new(:heart, :A), 1])
mm.generate(tree, mm.player_hand, mm.computer_hand, mm.player_points, mm.computer_points, true, 0)

puts tree
# tree.print_tree
# puts tree.children[0].content
# puts tree.children[1].content
# puts tree.children.each{|x| puts x.content }
# puts mm.minimax(tree)
puts mm.minimax(tree).parentage
# puts tree.children[1]
# puts tree.children[2].children[1].children
# puts mm.compare_nodes(tree.children[0].content,tree.children[1].content)

# puts tree.each_leaf{ |x| puts ["aaaaaaaaaaa"] +[x.content] + x.parentage.map{|x| x.content} + ["bbbbbbbbbb"] if x.content.size >1 and x.content[2][0] == :computer}
# tree.breadth_each {|x| p x.content}