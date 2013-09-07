defmodule Echo do
  use Reagent.Behaviour

  def handle(Reagent.Connection[socket: socket]) do
    socket |> Socket.Stream.send!(socket |> Socket.Stream.recv!)
    socket |> Socket.close
  end
end
