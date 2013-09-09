#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defrecord Reagent.Connection, socket: nil, id: nil, pool: nil, listener: nil, details: nil do
  def secure?(__MODULE__[socket: socket]) when is_record(socket, Socket.TCP) do
    false
  end

  def secure?(__MODULE__[socket: socket]) when is_record(socket, Socket.SSL) do
    true
  end

  def negotiated_protocol(__MODULE__[socket: socket] = self) do
    if secure?(self) do
      socket |> Socket.SSL.negotiated_protocol
    end
  end
end

defimpl Socket.Protocol, for: Reagent.Connection do
  use Socket.Helpers

  defwrap equal?(self, other)

  defwrap accept(self)
  defwrap accept(self, options)

  defwrap options(self, options)
  defwrap packet(self, type)
  defwrap process(self, pid)

  defwrap active(self)
  defwrap active(self, mode)
  defwrap passive(self)

  defwrap local(self)
  defwrap remote(self)

  defwrap close(self)
end

defimpl Socket.Stream.Protocol, for: Reagent.Connection do
  use Socket.Helpers

  defwrap send(self, data)
  defwrap file(self, path, options)

  defwrap recv(self)
  defwrap recv(self, length_or_options)
  defwrap recv(self, length, options)

  defwrap shutdown(self)
  defwrap shutdown(self, how)
end
