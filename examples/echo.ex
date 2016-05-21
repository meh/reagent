defmodule Echo do
  use Reagent.Behaviour

  def handle(conn) do
    case conn |> Socket.Stream.recv! do
      nil ->
        :closed

      data ->
        conn |> Socket.Stream.send!(data)

        handle(conn)
    end
  end
end
