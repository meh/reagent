#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Connection do
  alias __MODULE__, as: C

  defstruct [:socket, :id, :listener]

  @doc false
  def new(descriptor) do
    id       = make_ref
    socket   = Keyword.fetch! descriptor, :socket
    listener = Keyword.fetch! descriptor, :listener

    %C{socket: socket, id: id, listener: listener}
  end

  @doc """
  Get the environment for the connection.
  """
  @spec env(t) :: term
  def env(self) do
    Reagent.Listener.env_for(self.listener, self.id)
  end

  @doc """
  Set the environment for the connection.
  """
  @spec env(t, term) :: term
  def env(self, value) do
    Reagent.Listener.env_for(self.listener, self.id, value)
  end

  @doc """
  Check if the connection is secure or not.
  """
  @spec secure?(t) :: boolean
  def secure?(%C{socket: socket}) when socket |> is_port, do: false
  def secure?(%C{socket: socket}) when socket |> is_record(:sslsocket), do: true

  @doc """
  Get the SSL next negotiated protocol.
  """
  @spec negotiated_protocol(t) :: nil | String.t
  def negotiated_protocol(%C{socket: socket}) when socket |> is_record(:sslsocket) do
    socket |> Socket.SSL.negotiated_protocol
  end

  def negotiated_protocol(_) do
    nil
  end

  defimpl Socket.Protocol do
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

  defimpl Socket.Stream.Protocol do
    use Socket.Helpers

    defwrap send(self, data)
    defwrap file(self, path, options)

    defwrap recv(self)
    defwrap recv(self, length_or_options)
    defwrap recv(self, length, options)

    defwrap shutdown(self)
    defwrap shutdown(self, how)
  end
end
