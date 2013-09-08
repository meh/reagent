defmodule Echo do
  use Reagent.Behaviour

  def handle(conn) do
    conn |> Socket.Stream.send!(conn |> Socket.Stream.recv!)
    conn |> Socket.close
  end
end
