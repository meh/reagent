#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent do
  @spec start(Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start(listeners) do
    start([], listeners)
  end

  @spec start(module, Keyword.t, Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start(module, options, listeners) do
    start(Keyword.merge(options, module: module), listeners)
  end

  @spec start(module | Keyword.t, Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start(module, listeners) when module |> is_atom do
    start([module: module], listeners)
  end

  def start(options, listeners) do
    :gen_server.start __MODULE__, [options, listeners], []
  end

  @spec start_link(Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start_link(listeners) do
    start_link([], listeners)
  end

  @spec start_link(module, Keyword.t, Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start_link(module, options, listeners) do
    start_link(Keyword.merge(options, module: module), listeners)
  end

  @spec start_link(module | Keyword.t, Keyword.t | [Keyword.t]) :: { :ok, pid } | { :error, term }
  def start_link(module, listeners) when module |> is_atom do
    start_link([module: module], listeners)
  end

  def start_link(options, listeners) do
    :gen_server.start_link __MODULE__, [options, listeners], []
  end

  @doc """
  Wait for the ack.
  """
  @spec wait          :: :ok
  @spec wait(timeout) :: :ok | { :timeout, timeout }
  def wait(timeout // :infinity) do
    receive do
      { Reagent, :ack } ->
        :ok
    after
      timeout ->
        { :timeout, timeout }
    end
  end

  @doc """
  Add a new listener to the reagent.
  """
  @spec listen(pid, Keyword.t) :: :ok | { :error, term }
  def listen(pool, descriptor) do
    :gen_server.call(pool, { :listen, descriptor })
  end

  @doc """
  Get the total number of connections in this reagent.
  """
  @spec count(pid) :: non_neg_integer
  def count(pool) do
    :gen_server.call(pool, :count)
  end

  @doc """
  Get the number of connections in the given listener.
  """
  @spec count(pid, Listener.t | reference) :: non_neg_integer
  def count(pool, listener) do
    :gen_server.call(pool, { :count, listener })
  end

  use GenServer.Behaviour

  alias Reagent.Listener
  alias Reagent.Connection

  alias Data.Seq
  alias Data.Dict

  defrecord State, options: nil, listeners: HashDict.new, connections: HashDict.new, count: HashDict.new, waiting: HashDict.new

  def init([options, listeners]) do
    if Seq.first(listeners) |> is_tuple do
      listeners = [listeners]
    end

    listeners = Seq.map listeners, &create(options, &1)
    error     = listeners |> Seq.find_value fn
      { :error, reason } ->
        { :stop, reason }

      { :ok, _ } ->
        false
    end

    if error do
      error
    else
      listeners = HashDict.new listeners, fn { :ok, listener } ->
        { listener.id, listener }
      end

      Process.flag :trap_exit, true

      { :ok, State[options: options, listeners: listeners] }
    end
  end

  defp create(global, listener) do
    listener = Listener.new(Keyword.merge(global, listener))
    listener = listener.id(make_ref)
    listener = listener.pool(Process.self)

    if listener.module do
      socket = if listener.secure? do
        Socket.SSL.listen listener.port, listener.to_options
      else
        Socket.TCP.listen listener.port, listener.to_options
      end

      case socket do
        { :ok, socket } ->
          listener = listener.socket(socket)
          listener = listener.acceptors(Seq.map(1 .. listener.acceptors, fn _ ->
            listener.module.start_link(Process.self, listener)
          end))

          { :ok, listener }

        { :error, _ } = error ->
          error
      end
    else
      { :error, :no_module }
    end
  end

  # adds a new listener at runtime
  def handle_call({ :listen, listener }, _from, State[options: options, listeners: listeners] = state) do
    case create(options, listener) do
      { :ok, listener } ->
        listeners = listeners |> Dict.put(listener.id, listener)

        { :reply, :ok, state.listeners(listeners) }

      { :error, _ } = error ->
        { :reply, error, state }
    end
  end

  # accepts a new connection, as long as the pid is still alive
  def handle_call({ :accepted, Connection[listener: Listener[id: id]] = conn, pid }, _from, State[connections: connections, count: count] = state) do
    if Process.alive?(pid) do
      Process.link pid

      count       = count |> Dict.update(id, 0, &(&1 + 1))
      count       = count |> Dict.update(:total, 0, &(&1 + 1))
      connections = connections |> Dict.put(pid, conn)

      state = state.count(count)
      state = state.connections(connections)
    end

    { :reply, :ok, state }
  end

  # makes the caller wait in case the maximum connections threshold has been
  # reached, must be called with :infinity timeout or shit hits the fan
  def handle_call({ :wait, Listener[] = listener }, from, State[options: options, count: listeners, waiting: waiting] = state) do
    cond do
      # max pool wide connections reached
      options[:max_connections] && listeners[:total] || 0 >= options[:max_connections] ->
        waiting = waiting |> Dict.update(listener.id, [], &[from | &1])

        { :noreply, state.waiting(waiting) }

      # max listener specific connections number reached
      listener.options[:max_connections] && listeners[listener.id] || 0 >= listener.options[:max_connections] ->
        waiting = waiting |> Dict.update(listener.id, [], &[from | &1])

        { :noreply, state.waiting(waiting) }

      # all good, keep going
      true ->
        { :reply, :ok, state }
    end
  end

  # get the total number of connections
  def handle_call(:count, _from, State[count: listeners] = _state) do
    { :reply, listeners[:total] || 0, _state }
  end

  # get the number of connections on the given listener
  def handle_call({ :count, listener }, _from, State[count: listeners] = _state) do
    if listener |> is_record Listener do
      listener = listener.id
    end

    { :reply, listeners[listener] || 0, _state }
  end

  # some monitored process died, most likely a connection
  def handle_info({ :EXIT, pid, _reason }, State[listeners: listeners, connections: connections, waiting: waiting, count: count] = state) do
    case connections |> Dict.get(pid) do
      Connection[listener: Listener[id: id]] ->
        count       = count |> Dict.update(id, &(&1 - 1))
        count       = count |> Dict.update(:total, &(&1 - 1))
        connections = connections |> Dict.delete(pid)

        case waiting[id] do
          [wait | rest] ->
            :gen_server.reply(wait, :ok)

            waiting = waiting |> Dict.put(id, rest)

          _ ->
            nil
        end

        state = state.count(count)
        state = state.connections(connections)
        state = state.waiting(waiting)

      nil ->
        listener = Listener[id: id, acceptors: acceptors] = Seq.find_value listeners, fn { _, Listener[acceptors: acceptors] = listener } ->
          if Seq.contains?(acceptors, pid) do
            listener
          end
        end

        listener = Seq.map(acceptors, fn
          ^pid ->
            listener.module.start_link(Process.self, listener.acceptors(length(acceptors)))

          acceptor ->
            acceptor
        end) |> listener.acceptors

        state = listeners |> Dict.put(id, listener)
    end

    { :noreply, state }
  end
end
