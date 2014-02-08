require_relative 'constants.rb'
require_relative 'card.rb'
require_relative 'deck.rb'
require_relative 'player.rb'
require_relative 'computer.rb'
class Set
  attr_accessor :state

  def initialize()
    @full_deck = Deck.new([])
    Constants::SUITS.each do |s, _|
      Constants::VALUES.each do |v, _|
        @full_deck.add(Card.new(s,v))
      end
    end
    @state = :open
    @turn = rand(2)
  end

  # def trump_set(suit)
  #   SUITS.each { |s, v| SUITS[s] = s == suit ? 4 : v - 1 }
  # end

  def draw
    @full_deck.shuffle
    player_cards, computer_cards = [], []
    2.times do
      3.times { player_cards << @full_deck.remove() }
      3.times { computer_cards << @full_deck.remove() }
    end
    @trump = @full_deck.remove()
    Constants.trump_set(@trump.suit)
    @full_deck.add(@trump)
    @player = Player.new(:player, player_cards)
    @computer = Computer.new(computer_cards)
    # puts @computer.possible_player_hand
  end

  def exchange_nine_of_trumps(player)
    nine_of_trumps = Card.new(@trump.suit, 9)
    @full_deck.remove(@trump)
    player.hand.add(@trump)
    player.hand.remove(nine_of_trumps)
    @full_deck.add(nine_of_trumps)
    @trump = nine_of_trumps
  end

  def score_calculate
    winner = check_for_set_winner
    loser = winner == :player ? @computer : @player
    if loser.points == 0
      [3, winner]
    elsif loser.points < 33
      [2, winner]
    else
      [1, winner]
    end
  end

  def move(round)#refactor
    if @turn.zero?
      puts self
      if @player.check_for_nine_of_trumps(@trump) and round.between?(2, 5)#9 s logic
        puts "Do you want to exchange 9 of trups? [y, n]\n"
        answer = gets
        if answer.to_s.downcase.match(/y/)#unknown why == doesnt work
          exchange_nine_of_trumps(@player)
          puts self
        end
      end
      if @state == :open and round.between?(2, 5)#possible refactor
        puts "Do you want to close? [y, n]\n"
        answer = gets
        if answer.to_s.downcase.match(/y/)
          @state = :closed
          puts self
        end
      end
      get_player_move
      @player.points += @player.pair_points(@player_move, @trump)
      puts self
      return score_calculate if !check_for_set_winner.nil?
      @computer.possible_player_hand.delete(@player_move)
      get_computer_move
      points_update
      return score_calculate if !check_for_set_winner.nil?
      turn_update
      if @state == :open and !@full_deck.empty?
        @player.draw_card(@full_deck.remove())
        card_drawn = @full_deck.remove()
        @computer.draw_card(card_drawn)
        @computer.possible_player_hand.delete(card_drawn)
      end
      puts self
    else
      if @computer.check_for_nine_of_trumps(@trump) and round.between?(2, 5)
        exchange_nine_of_trumps(@computer)
      end
      get_computer_move
      @computer.points += @computer.pair_points(@computer_move, @trump)
      puts self
      return score_calculate if !check_for_set_winner.nil?
      get_player_move_with_validation(@state)
      @computer.possible_player_hand.delete(@player_move)
      points_update
      return score_calculate if !check_for_set_winner.nil?
      turn_update
      if @state == :open and !@full_deck.empty?
        card_drawn = @full_deck.remove()
        @computer.draw_card(card_drawn)
        @computer.possible_player_hand.delete(card_drawn)
        @player.draw_card(@full_deck.remove())
      end
      puts self
    end
  end

  def moves(state)
    1.upto(12) do |round|
      if @state == :open and round > 6
        @state = :final
      end 
      puts "round #{round}"
      result = move(round)
      if !result.nil?
        puts result
        break
      end
      # if @computer.points >= 66
      #   puts "Computer wins\n"
      #   break
      # elsif @player.points >= 66
      #   puts "Player wins\n"
      #   break
      # elsif round == 12
      #   if evaluate_move_winner(@turn) == 1
      #     @player.points += 11
      #     puts "Player wins\n"
      #   else
      #     @computer.points += 11
      #     puts "Computer wins\n"
      #   end
      # else
        @player_move = nil
        @computer_move = nil
      # end
    end
  end


  def evaluate_move_winner(turn)#1 if player win -1 else
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

  def check_for_set_winner
    if @player.points >= 66
      :player
    elsif @computer.points >= 66
      :computer
    else
      nil
    end
  end

  def points_update
    move_value = Constants::VALUES[@player_move.value] + Constants::VALUES[@computer_move.value]
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

  def get_player_move_with_validation(state)#get player move when closed
    puts "Enter the position [0..5] of the card you want to play: "
    position = gets.to_i
    unless (0..5).include?(position.to_i)
      puts "Invalid position\n"
      return get_player_move_with_validation(state)
    end
    sorted_hand = @player.hand.deck.sort
    sorted_indexes = {}
    sorted_hand.each_with_index { |card, i| sorted_indexes[i] = card }
    if state == :closed or state == :final
      if !@player.valid_move?(@trump, sorted_indexes[position.to_i], @computer_move)
        puts "Invalid move\n"
        return get_player_move_with_validation(state)
      end
    end
    @player_move = @player.hand.remove(sorted_indexes[position.to_i])
  end

  def get_computer_move
    computer_choice = @computer.evaluate_hand(@trump, @state, @turn, @player_move)
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

# deck1 = Deck.new([a,b,c])
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


 # puts deck.select { |card| !deck1.include?(card)}
