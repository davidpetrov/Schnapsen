describe "Schnapsen" do
  describe "Card" do
    it "compares cards with =="  do
      (Card.new(:diamond, 9) == Card.new(:diamond, 9)).should be_true
      (Card.new(:diamond, 9) == Card.new(:diamond, 10)).should be_false
      (Card.new(:club, :A) == Card.new(:diamond, :A)).should be_false
    end
  end
end