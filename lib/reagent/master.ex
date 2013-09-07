defmodule Reagent.Master do
  use GenServer.Behaviour

  alias Reagent.Listener
  alias Data.Seq
  alias Data.Dict

  defrecord State, listeners: [], connections: HashDict.new

  def init([module, options]) do
    Process.flag :trap_exit, true

    if Seq.first(options) |> is_tuple do
      options = [options]
    end

    listeners = Seq.map options, &create(module, &1)
    error     = listeners |> Seq.find_value fn
      { :error, _ } = error ->
        error

      { :ok, _ } ->
        false
    end

    if error do
      error
    else
      { :ok, State[listeners: Seq.map(listeners, &elem(&1, 1))] }
    end
  end

  defp create(module, options) do
    listener = Listener.new(options)
    listener = listener.master Process.self

    socket = if listener.secure? do
      Socket.SSL.listen listener.port, listener.to_options
    else
      Socket.TCP.listen listener.port, listener.to_options
    end

    case socket do
      { :ok, socket } ->
        listener = listener.socket(socket)
        listener = listener.acceptors(Seq.map(1 .. listener.acceptors, fn _ ->
          module.start_link(Process.self, listener)
        end))

        { :ok, listener }

      { :error, _ } = error ->
        error
    end
  end

  def handle_cast({ :accepted, conn, pid }, State[connections: connections] = state) do
    if Process.alive?(pid) do
      Process.link pid

      connections = connections |> Dict.put(pid, conn)
      state       = state.connections connections
    end

    { :noreply, state }
  end

  def handle_call(:count, _from, State[connections: connections] = _state) do
    { :reply, Data.count(connections), _state }
  end

  def handle_call({ :count, listener }, _from, State[connections: connections] = _state) do
    { :reply, Seq.count(connections, &(&1.listener == listener)), _state }
  end

  def handle_info({ :EXIT, pid, reason }, State[listeners: listeners, connections: connections] = state) do
    if connections |> Dict.has_key?(pid) do
      state = connections |> Dict.delete(pid) |> state.connections
    end

    { :noreply, state }
  end
end
