defrecord Reagent.Connection, listener: nil, socket: nil, details: nil do
  def secure?(__MODULE__[socket: socket]) when is_record(socket, Socket.TCP) do
    false
  end

  def secure?(__MODULE__[socket: socket]) when is_record(socket, Socket.SSL) do
    true
  end
end
