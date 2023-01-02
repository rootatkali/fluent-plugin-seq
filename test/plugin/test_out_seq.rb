require "helper"
require "fluent/plugin/out_seq.rb"

class SeqOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::SeqOutput).configure(conf)
  end
end
