#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Master do
  use GenServer.Behaviour

  alias Reagent.Listener
  alias Reagent.Connection

  alias Data.Seq
  alias Data.Dict

  defrecord State, listeners: HashDict.new, connections: HashDict.new, count: HashDict.new, waiting: HashDict.new

  def init([module, details, listeners]) do
    Process.flag :trap_exit, true

    if Seq.first(listeners) |> is_tuple do
      listeners = [listeners]
    end

    listeners = Seq.map listeners, &create(module, details, &1)
    error     = listeners |> Seq.find_value fn
      { :error, _ } = error ->
        error

      { :ok, _ } ->
        false
    end

    if error do
      error
    else
      listeners = HashDict.new listeners, fn { :ok, listener } ->
        { listener.id, listener }
      end

      { :ok, State[listeners: listeners] }
    end
  end

  defp create(module, details, listener) do
    listener = Listener.new(listener)
    listener = listener.id(make_ref)
    listener = listener.master(Process.self)

    if details do
      listener = listener.details details
    end

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

  def handle_cast({ :accepted, Connection[listener: Listener[id: id]] = conn, pid }, State[connections: connections, count: count] = state) do
    if Process.alive?(pid) do
      Process.link pid

      count       = count |> Dict.update(id, 0, &(&1 + 1))
      connections = connections |> Dict.put(pid, conn)

      state = state.count(count)
      state = state.connections(connections)
    end

    { :noreply, state }
  end

  def handle_call({ :wait, listener }, from, State[count: listeners, waiting: waiting] = state) do
    count = listeners[listener.id]
    max   = listener.options[:max_connections]

    if max && count > max do
      waiting = waiting |> Dict.put(listener.id, from)

      { :noreply, state.waiting(waiting) }
    else
      { :reply, :ok, state }
    end
  end

  def handle_call(:count, _from, State[count: listeners] = _state) do
    { :reply, Seq.reduce(listeners, 0, &(elem(&1, 1) + &2)), _state }
  end

  def handle_call({ :count, listener }, _from, State[count: listeners] = _state) do
    { :reply, listeners[listener.id] || 0, _state }
  end

  def handle_info({ :EXIT, pid, _reason }, State[listeners: listeners, connections: connections, waiting: waiting, count: count] = state) do
    if Connection[listener: Listener[id: id]] = connections |> Dict.get(pid) do
      count       = count |> Dict.update(id, &(&1 - 1))
      connections = connections |> Dict.delete(pid)

      if wait = waiting[id] do
        :gen_server.reply(wait, :ok)

        waiting = waiting |> Dict.delete(id)
      end

      state = state.count(count)
      state = state.connections(connections)
      state = state.waiting(waiting)
    end

    Enum.each listeners, fn { _, Listener[acceptors: acceptors] } ->
      Enum.each acceptors, fn acceptor ->
        if acceptor == pid do
          IO.puts "BIP BIP BIP"
        end
      end
    end

    { :noreply, state }
  end
end
