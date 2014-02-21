describe "Schnapsen" do
  describe "Card" do
    it "can't be constructed with no arguments" do
      expect { Schnapsen::Card.new }.to raise_error(ArgumentError)
    end

    it "exposes its suit and value via getters" do
      card = make_card :spade, 10
      card.suit.should eq :spade
      card.value.should eq 10
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


  end

  def make_card(*args)
    Schnapsen::Card.new(*args)
  end
end