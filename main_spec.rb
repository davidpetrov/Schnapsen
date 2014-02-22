require 'set'
describe "Schnapsen" do
  it "is defined as a top-level constant" do
    Object.const_defined?(:Schnapsen).should be_true
  end

  describe "Card" do
    it "can't be constructed with no arguments" do
      expect { Schnapsen::Card.new }.to raise_error(ArgumentError)
    end

    it "exposes its suit and value via getters" do
      card = make_card :spade, 10
      card.suit.should eq :spade
      card.value.should eq 10
    end

    it "does not expose setters for the suit or value" do
      card = make_card :spade, 10
      card.should_not respond_to :suit=
      card.should_not respond_to :value=
      expect { card.value = 10 }.to raise_error(NoMethodError)
    end

    it "compares cards with =="  do
      (make_card(:diamond, 9) == make_card(:diamond, 9)).should be_true
      (make_card(:diamond, 9) == make_card(:diamond, 10)).should be_false
      (make_card(:club, :A) == make_card(:diamond, :A)).should be_false
    end

    it "compares card with < and >" do
      (make_card(:diamond, 9) < make_card(:diamond, 9)).should be_false
      (make_card(:diamond, 9) < make_card(:diamond, 10)).should be_true
      (make_card(:club, :A) > make_card(:diamond, :A)).should be_false
      (make_card(:club, :A) > make_card(:diamond, :K)).should be_false
      (make_card(:spade, :Q) > make_card(:diamond, :Q)).should be_true
    end

    it "compares with eql?" do
      (make_card(:diamond, 9).eql? make_card(:diamond, 9)).should be_true
      (make_card(:diamond, 9).eql? make_card(:diamond, 10)).should be_false
      (make_card(:club, :A).eql? make_card(:diamond, :A)).should be_false
    end

    it "has unique hash function" do
      (make_card(:diamond, 9).hash.eql? make_card(:diamond, 9).hash).should be_true
      (make_card(:diamond, :A).hash.eql? make_card(:diamond, 9).hash).should be_false
      (make_card(:spade, :K).hash.eql? make_card(:diamond, :K).hash).should be_false
    end

    it "has string representation" do
      make_card(:spade, 9).to_s.should eq "9♠"
      make_card(:diamond, :K).to_s.should eq "K♦"
      make_card(:club, :Q).to_s.should eq "Q♣"
      make_card(:heart, :A).to_s.should eq "A♥"
    end
  end

  describe "Deck" do
    it "can't be constructed with no arguments" do
      expect { Schnapsen::Deck.new }.to raise_error(ArgumentError)
    end
    let(:cards) { [make_card(:spade, 9),
                   make_card(:diamond, 10),
                   make_card(:heart, :A),
                   make_card(:club, :J),
                   make_card(:club, 9),
                   make_card(:diamond, :Q),
    ] }
    let(:deck) { make_deck(cards) }
    it "exposes its deck and size via getters" do
      deck.deck.should eq cards
      deck.size.should eq 6
    end

    it "does not expose setters for the deck or size" do
      deck.should_not respond_to :deck=
      deck.should_not respond_to :size=
      expect { deck.size = 10 }.to raise_error(NoMethodError)
    end

    it "includes enumerable" do
      deck.include?(make_card(:diamond, 10)).should be_true
      deck.select { |card| card.suit == :club}.should eq [make_card(:club, :J), make_card(:club, 9)]
      deck.min.should eq make_card(:club, 9)
      deck.max.should eq make_card(:spade, 9)
    end

    it "has string representation(in sorted order)" do
      deck.to_s.should eq "9♣ J♣ Q♦ 10♦ A♥ 9♠ "
    end

    it "can remove card at index" do
      deck.remove(0)
      deck.deck.should eq cards
    end

    it "can remove card by object" do
      deck.remove(make_card(:heart, :A))
      deck.deck.should eq cards
    end

    it "can add cards" do
      card = make_card(:spade, :J)
      deck.add(card)
      deck.deck.last.should eq card
    end

    it "has correct size after addition of a card" do
      card = make_card(:spade, :J)
      deck.add(card)
      deck.deck.size.should eq 7
    end

    it "respond to [] method" do
      deck[0].should eq cards[0]
      deck[5].should eq cards[5]
    end

    it "can be changed by []= method" do
      card = make_card(:spade, :A)
      deck[0] = card
      deck[0].should eq card
    end

    it "checks if empty" do
      make_deck([]).empty?.should be_true
      deck.empty?.should be_false
    end
  end

  describe "Player" do
    let(:cards) { [make_card(:spade, 9),
                   make_card(:diamond, 10),
                   make_card(:heart, :A),
                   make_card(:club, :J),
                   make_card(:club, 9),
                   make_card(:diamond, :Q),
    ] }
    let(:hand) { make_deck(cards) }
    let (:player) { make_player(:player, hand) }
    it "can't be constructed with no arguments" do
      expect { Schnapsen::Player.new }.to raise_error(ArgumentError)
    end

    it "exposes its name,hand and points via getters" do
      player.name.should eq :player
      player.hand.deck.to_set.should eq hand.deck.to_set
      player.points.should eq 0
    end

    it "does not expose setters for the name or hand" do
      player.should_not respond_to :name=
      player.should_not respond_to :hand=
      expect { player.hand = 10 }.to raise_error(NoMethodError)
    end

    context "pair checks" do
      it "checks for pair points when 0" do
        trump = make_card(:spade, :J)
        player.pair_points(hand[0], trump).should eq 0
        player.pair_points(hand[5], trump).should eq 0
      end

      it "checks for pair points when 20" do
        trump = make_card(:spade, :J)
        player.hand[4] = make_card(:diamond, :K)
        player.pair_points(hand[5], trump).should eq 20
      end

      it "checks for pair points when 40" do
        trump = make_card(:diamond, :J)
        player.hand[4] = make_card(:diamond, :K)
        player.pair_points(hand[5], trump).should eq 40
      end
    end
    it "checks for 9 of trumps" do
      trump = make_card(:diamond, :J)
      player.check_for_nine_of_trumps(trump).should be_false
      trump = make_card(:spade, :J)
      player.check_for_nine_of_trumps(trump).should be_true
    end

    context "move validation" do
      it "validates when every move is possible" do
        trump = make_card(:spade, :J)
        player.hand[0] = make_card(:heart, 9)
        player.hand.all? { |card| player.valid_move?(trump, card, trump).should be_true }
      end

      it "validates when same suit but unable to take" do
        trump = make_card(:spade, :J)
        player.valid_move?(trump, player.hand[3], make_card(:club, :A)).should be_true
        player.valid_move?(trump, player.hand[2], make_card(:club, :A)).should be_false
      end

      it "validates when same suit and able to take" do
        trump = make_card(:spade, :J)
        player.valid_move?(trump, player.hand[3], make_card(:diamond, :K)).should be_false
        player.valid_move?(trump, player.hand[5], make_card(:diamond, :K)).should be_false
        player.valid_move?(trump, player.hand[1], make_card(:diamond, :K)).should be_true
      end

      it "validates when must trump" do
        trump = make_card(:heart, :J)
        player.hand[0] = make_card(:heart, 9)
        player.valid_move?(trump, player.hand[3], make_card(:spade, :A)).should be_false
        player.valid_move?(trump, player.hand[0], make_card(:spade, :A)).should be_true
      end 
    end
  end

  describe "Computer" do
    let(:cards) { [make_card(:spade, 9),
                   make_card(:diamond, 10),
                   make_card(:heart, :A),
                   make_card(:club, :J),
                   make_card(:club, 9),
                   make_card(:diamond, :Q),
    ] }
    let(:hand) { make_deck(cards) }
    let (:computer) { make_computer(hand) }
    it "can't be constructed with no arguments" do
      expect { Schnapsen::Computer.new }.to raise_error(ArgumentError)
    end

    it "exposes its name,hand and points via getters" do
      computer.hand.deck.to_set.should eq hand.deck.to_set
      computer.points.should eq 0
    end

    it "does not expose setters for the hand" do
      computer.should_not respond_to :hand=
      expect { computer.hand = 10 }.to raise_error(NoMethodError)
    end

    context "pair checks" do
      it "checks for pair when none" do
        computer.find_pair(make_card(:spade, :J)).should eq nil
      end

      it "checks for pair when one pair" do
        trump = make_card(:spade, :J)
        computer.hand[4] = make_card(:diamond, :K)
        computer.find_pair(make_card(:spade, :J)).should eq make_card(:diamond, :Q)
      end

      it "checks for max points pair" do
        trump = make_card(:spade, :J)
        computer.hand[4] = make_card(:diamond, :K)
        computer.hand[0] = make_card(:spade, :K)
        computer.hand[1] = make_card(:spade, :Q)
        computer.find_pair(make_card(:spade, :J)).should eq make_card(:spade, :Q)
      end

      it "checks for pair points when 0" do
        trump = make_card(:spade, :J)
        computer.pair_points(hand[0], trump).should eq 0
        computer.pair_points(hand[5], trump).should eq 0
      end

      it "checks for pair points when 20" do
        trump = make_card(:spade, :J)
        computer.hand[4] = make_card(:diamond, :K)
        computer.pair_points(hand[5], trump).should eq 20
      end

      it "checks for pair points when 40" do
        trump = make_card(:diamond, :J)
        computer.hand[4] = make_card(:diamond, :K)
        computer.pair_points(hand[5], trump).should eq 40
      end
    end

    it "checks for 9 of trumps" do
      trump = make_card(:diamond, :J)
      computer.check_for_nine_of_trumps(trump).should be_false
      trump = make_card(:spade, :J)
      computer.check_for_nine_of_trumps(trump).should be_true
    end

    context "move evaluation" do
      context "open state" do
        context "on move" do
          it "plays pair when present" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :open, 1).should eq make_card(:spade, 9)
            computer.hand[4] = make_card(:diamond, :K)
            computer.evaluate_hand(trump, :open, 1).should eq make_card(:diamond, :Q)
          end

          it "plays min card when no pair" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :open, 1).should eq make_card(:spade, 9)
          end
        end

        context "not on move" do
          it "trumps high-value cards" do
            trump = make_card(:diamond, :J)
            computer.hand[0] = trump
            computer.evaluate_hand(trump, :open, 0, make_card(:spade, :A)).should eq make_card(:diamond, :J)
          end

          it "takes if possible with max-value card" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :open, 0, trump).should eq make_card(:diamond, 10)
          end

          it "plays min card if unable to take" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :open, 0, make_card(:club, :K)).should eq make_card(:spade, 9)
          end
        end
      end

      context "closed or final state" do
        context "on move" do 
          it "plays max card" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :closed, 1).should eq make_card(:spade, 9)
          end
        end

        context "not on move" do
          it "takes if possible with max-value card" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :closed, 0, trump).should eq make_card(:diamond, 10)
          end

          it "plays min card of the same suit if unable to take" do
            trump = make_card(:diamond, :J)
            computer.evaluate_hand(trump, :closed, 0, make_card(:club, :A)).should eq make_card(:club, 9)
          end

          it "plays min card if unable to take or trump" do
            trump = make_card(:spade, :A)
            computer.hand[0] = make_card(:heart, 9)
            computer.evaluate_hand(trump, :closed, 0, trump).should eq make_card(:club, 9)
          end

          it "trumps with max-value trump if necessary" do
            trump = make_card(:diamond, :J)
            computer.hand[0] = make_card(:heart, 9)
            computer.evaluate_hand(trump, :closed, 0, make_card(:spade, :A)).should eq make_card(:diamond, 10)
          end
        end
      end
    end
  end

  def make_card(*args)
    Schnapsen::Card.new(*args)
  end

  def make_deck(*args)
    Schnapsen::Deck.new(*args)
  end

  def make_player(*args)
    Schnapsen::Player.new(*args)
  end

  def make_computer(*args)
    Schnapsen::Computer.new(*args)
  end
end