class UserInterface
  def initialize(board)
    @board = board
  end

  def display_board(player_points, computer_points,player_hand, computer_hand)
    output = ""
    output << "Computer:      #{computer_hand}".ljust(40) + "#{computer_points}\n"
    output << "-------------------------------------------------------\n\n"
    output << "[#{@board.state}]".ljust(20) + "#{@board.computer_move}\n"
    output << "#{@board.trump}".ljust(20) + "#{@board.player_move}\n\n"
    output << "-------------------------------------------------------\n"
    output << "Player:        #{player_hand}".ljust(40) + "#{player_points}\n"
    output << " " * 15 +  player_hand.to_s.split(' ').to_a.map(&:length).zip(0.upto(5).to_a).map do |l, i|
      i.to_s.ljust(l + 1)
    end.join
    puts output
  end

  def exchange_9_prompt
    puts "Do you want to exchange 9 of trumps? [y, n]\n"
  end

  def closed_state_prompt
    puts "Do you want to close? [y, n]\n"
  end

  def answer
    input = gets
    input.to_s.downcase.match(/y/)
  end
end