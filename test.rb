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
# ..... Create the root node first.  Note that every node has a name and an optional content payload.
# root_node = Tree::TreeNode.new("ROOT", "Root Content")
# root_node.print_tree

# # ..... Now insert the child nodes.  Note that you can "chain" the child insertions for a given path to any depth.
# root_node << Tree::TreeNode.new("CHILD1", "Child1 Content") << Tree::TreeNode.new("GRANDCHILD1", "GrandChild1 Content")
# root_node << Tree::TreeNode.new("CHILD2", "Child2 Content")

# # ..... Lets print the representation to stdout.  This is primarily used for debugging purposes.
# root_node.print_tree

# # ..... Lets directly access children and grandchildren of the root.  The can be "chained" for a given path to any depth.
# child1       = root_node["CHILD1"]
# grand_child1 = root_node["CHILD1"]["GRANDCHILD1"]

# # ..... Now lets retrieve siblings of the current node as an array.
# siblings_of_child1 = child1.siblings

# # ..... Lets retrieve immediate children of the root node as an array.
# children_of_root = root_node.children

# # ..... This is a depth-first and L-to-R pre-ordered traversal.
# root_node.each { |node| node.content.reverse }

# # ..... Lets remove a child node from the root node.
# root_node.remove!(child1)

# card1 = Card.new(:spade, :J)

# root = Tree::TreeNode.new(card1.to_s, card1)
# root<< Tree::TreeNode.new(Card.new(:diamond, :J).to_s, Card.new(:diamond, :J) )
# root<< Tree::TreeNode.new(Card.new(:club, 9).to_s, Card.new(:club, 9) )
# root[Card.new(:club, 9).to_s] << Tree::TreeNode.new(Card.new(:club, 10).to_s, Card.new(:club, 10) )
# root[Card.new(:diamond, :J).to_s] << Tree::TreeNode.new(Card.new(:heart, :A).to_s, Card.new(:heart, :A) )
# root.print_tree
# root.postordered_each{|x| puts x}

# arr1 = []
# VALUES.keys.each { |i| arr1 << Card.new(:club, i)  }
# deck1 = Deck.new(arr1)
# arr2 = []
# VALUES.keys.each { |i| arr2 << Card.new(:diamond, i)  }
# deck2 = Deck.new(arr2)

# puts deck1
# puts deck2

# TREE = Tree::TreeNode.new(deck1[0].to_s,deck1[0])


  # deck1.remove(deck1[0])
  # deck2.each do |card|
  #   TREE << Tree::TreeNode.new(card.to_s, card)
  #   deck1.each do |card1| 
  #     TREE[card.to_s] << Tree::TreeNode.new(card1.to_s, card1)
  #   end
  #  end

  # def generate_tree(root, hand1, hand2)
#   hand1.remove(root)
#   puts hand1
#   hand2.each do |card|
#     TREE << Tree::TreeNode.new(card.to_s, card)
#     # generate_tree(card, hand2,hand1)
#   end
# end

# generate_tree(deck1[0],deck1,deck2)
# TREE.print_tree
# # p TREE.methods.select {|x| x.match(/root/)}
# puts TREE.root.is_root

class Minimax
  attr_accessor :player_hand, :computer_hand, :trump, :comuter_points, :player_points, :turn
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

  def generate(turn = 0, player_points, computer_points)
    root = turn == 0 ? @player_hand.remove() : @computer_hand.remove()
    hand = turn == 0 ? @computer_hand : @player_hand
    tree = Tree::TreeNode.new(root.to_s, root)
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
        set_winner = check_for_set_winner(p_points, c_points)
        if set_winner.nil?
          tree << Tree::TreeNode.new(card.to_s + outcome.to_s + p_points.to_s + c_points.to_s, [card, outcome, p_points, c_points])
        else
          tree << Tree::TreeNode.new(card.to_s + outcome.to_s + set_winner.to_s , [card, outcome, set_winner])
        end
      end
    end
    tree.print_tree
    puts tree.is_root?
  end
end


mm = Minimax.new
puts "trump #{mm.trump}"
puts mm.player_hand
puts mm.computer_hand
puts mm.player_points
puts mm.comuter_points
mm.generate(1, mm.player_points, mm.comuter_points)

