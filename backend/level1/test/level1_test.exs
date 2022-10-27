defmodule Level1Test do
  use ExUnit.Case
  doctest Level1

  test "greets the world" do
    assert Level1.hello() == :world
  end
end
