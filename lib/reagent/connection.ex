#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Connection do
  @opaque t :: record

  defrecordp :connection, __MODULE__, socket: nil, id: nil, listener: nil

  @doc false
  def new(descriptor) do
    id       = make_ref
    socket   = Keyword.fetch! descriptor, :socket
    listener = Keyword.fetch! descriptor, :listener

    connection(socket: socket, id: id, listener: listener)
  end

  @doc """
  Get the id of the connection.
  """
  @spec id(t) :: reference
  def id(connection(id: id)) do
    id
  end

  @doc """
  Get the listener of the connection.
  """
  @spec listener(t) :: Reagent.Listener.t
  def listener(connection(listener: listener)) do
    listener
  end

  @doc """
  Get the environment for the connection.
  """
  @spec env(t) :: term
  def env(connection(id: id, listener: listener)) do
    Reagent.Listener.env_for(listener, id)
  end

  @doc """
  Set the environment for the connection.
  """
  @spec env(t, term) :: term
  def env(connection(id: id, listener: listener), value) do
    Reagent.Listener.env_for(listener, id, value)
  end

  @doc """
  Check if the connection is secure or not.
  """
  @spec secure?(t) :: boolean
  def secure?(connection(socket: socket)) when is_record(socket, Socket.TCP) do
    false
  end

  def secure?(connection(socket: socket)) when is_record(socket, Socket.SSL) do
    true
  end

  @doc """
  Get the SSL next negotiated protocol.
  """
  @spec negotiated_protocol(t) :: nil | String.t
  def negotiated_protocol(connection(socket: socket) = self) do
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
