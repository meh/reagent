#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Listener do
  defstruct socket: nil, id: nil, module: nil, port: nil, secure: nil, options: [],
    env: nil, acceptors: nil, connections: nil, waiting: nil

  @opaque t :: %Reagent.Listener{}

  use GenServer
  use Data

  @doc """
  Get the environment for the listener.
  """
  @spec env(pid | t) :: term
  def env(%__MODULE__{} = self) do
    self.env |> Dict.get(self.id)
  end

  def env(id) do
    GenServer.call(id, :env) |> Dict.get(id)
  end

  @doc """
  Set the environment for the listener.
  """
  @spec env(pid | t, reference | term) :: term
  def env(%__MODULE__{} = self, value) do
    self.env |> Dict.put(self.id, value)

    value
  end

  def env(id, value) do
    GenServer.call(id, :env) |> Dict.put(id, value)

    value
  end

  @doc false
  def env_for(self, conn) do
    self.env |> Dict.get(conn)
  end

  @doc false
  def env_for(self, conn, value) do
    self.env |> Dict.put(conn, value)

    value
  end

  @doc """
  Check if the connection is secure or not.
  """
  @spec secure?(t) :: boolean
  def secure?(%__MODULE__{secure: nil}), do: false
  def secure?(%__MODULE__{}),            do: true

  @doc """
  Get the certificate of the listener.
  """
  @spec cert(t) :: String.t
  def cert(%__MODULE__{secure: nil}), do: nil
  def cert(%__MODULE__{secure: sec}), do: sec[:cert]

  @doc false
  def start(descriptor) do
    GenServer.start __MODULE__, descriptor
  end

  @doc false
  def start_link(descriptor) do
    GenServer.start_link __MODULE__, descriptor
  end

  @doc false
  def init(descriptor) do
    if descriptor[:profile] do
      Reagent.Profile.start
    end

    id        = Kernel.self
    module    = Keyword.fetch! descriptor, :module
    port      = Keyword.fetch! descriptor, :port
    secure    = Keyword.get    descriptor, :secure
    acceptors = Keyword.get    descriptor, :acceptors, 100
    options   = Keyword.get    descriptor, :options, []

    socket = if secure do
      Socket.SSL.listen port, to_options(options, secure)
    else
      Socket.TCP.listen port, to_options(options)
    end

    case socket do
      { :ok, socket } ->
        Process.flag :trap_exit, true

        dict = Exts.Dict.new(access: :public)
        dict |> Dict.put(id, descriptor[:env])

        listener = %__MODULE__{
          socket:      socket,
          id:          id,
          module:      module,
          port:        port,
          secure:      secure,
          options:     options,
          env:         dict,
          acceptors:   MapSet.new,
          connections: Map.new,
          waiting:     :queue.new }

        GenServer.cast Kernel.self, { :acceptors, acceptors }

        { :ok, listener }

      { :error, reason } ->
        { :stop, reason }
    end
  end

  defp to_options(options) do
    options |> Keyword.merge(mode: :passive, automatic: false)
  end

  defp to_options(options, secure) do
    options |> Keyword.merge(secure) |> Keyword.merge(mode: :passive, automatic: false)
  end

  @doc false
  def terminate(self, _) do
    self.socket |> Socket.close
  end

  @doc false
  def handle_call(:env, _from, %__MODULE__{env: env} = listener) do
    { :reply, env, listener }
  end

  def handle_call(:wait, from, self) do
    case Keyword.fetch(self.options, :max_connections) do
      :error ->
        { :reply, :ok, self }

      { :ok, max } ->
        if Data.count(self.connections) >= max do
          { :noreply, %__MODULE__{self | waiting: :queue.in(from, self.waiting)} }
        else
          { :reply, :ok, self }
        end
    end
  end

  @doc false
  def handle_cast({ :acceptors, number }, self) when number > 0 do
    pids = Enum.map(1 .. number, fn _ ->
      { :ok, pid } = Task.start_link __MODULE__, :acceptor, [self]; pid
    end) |> Enum.into(MapSet.new)

    { :noreply, %__MODULE__{self | acceptors: Set.union(self.acceptors, pids)} }
  end

  def handle_cast({ :acceptors, number }, self) when number < 0 do
    { keep, drop } = Enum.split(self.acceptors, -number)

    Enum.each drop, fn pid ->
      Process.exit pid, :drop
    end

    { :noreply, %__MODULE__{self | acceptors: keep |> Enum.into(MapSet.new)} }
  end

  def handle_cast({ :accepted, pid, conn }, self) do
    { :noreply, %__MODULE__{self | connections: self.connections |> Dict.put(Process.monitor(pid), conn)} }
  end

  @doc false
  def handle_info({ :EXIT, pid, _reason }, self) do
    acceptors = self.acceptors |> Set.delete(pid)
      |> Set.add(Kernel.spawn_link(__MODULE__, :acceptor, [self]))

    { :noreply, %__MODULE__{self | acceptors: acceptors } }
  end

  def handle_info({ :DOWN, ref, _type, _object, _info }, self) do
    connection  = self.connections |> Dict.get(ref)
    connections = self.connections |> Dict.delete(ref)

    connection |> Socket.close
    Dict.delete(self.env, connection.id)

    case :queue.out(self.waiting) do
      { :empty, queue } ->
        { :noreply, %__MODULE__{self | connections: connections, waiting: queue} }

      { { :value, from }, queue } ->
        GenServer.reply(from, :ok)

        { :noreply, %__MODULE__{self | connections: connections, waiting: queue} }
    end
  end

  @doc false
  def acceptor(self) do
    wait(self)

    case self.module.accept(self) do
      { :ok, socket } ->
        conn = Reagent.Connection.new(listener: self, socket: socket)

        case self.module.start(conn) do
          :ok ->
            self.module.handle(conn)

          { :ok, pid } ->
            socket |> Socket.process!(pid)
            pid |> send({ Reagent, :ack })

            GenServer.cast self.id, { :accepted, pid, conn }

            acceptor(self)

          { :error, reason } ->
            exit reason
        end

      { :error, reason } ->
        exit reason
    end
  end

  defp wait(self) do
    GenServer.call self.id, :wait
  end
end
