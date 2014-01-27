describe "Card" do
  it "compares cards with =="  do
    (Card.new(:diamond, 9) == Card.new(:diamond, 9)).should be_true
  end
end 

