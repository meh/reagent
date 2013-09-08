defmodule Reagent.Behaviour do
  use Behaviour

  alias Reagent.Listener
  alias Reagent.Connection

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @doc false
      def start_link(master, listener) do
        Process.spawn_link __MODULE__, :run, [master, listener]
      end

      @doc false
      def run(master, listener) do
        case accept(listener) do
          { :ok, socket } ->
            conn = Connection[id: make_ref, master: master, listener: listener, socket: socket]

            case start(conn) do
              { :ok, pid } ->
                socket |> Socket.process!(pid)

                :gen_server.cast master, { :accepted, conn, pid }
                pid <- { Reagent, :ack }

              { :error, _ } = error ->
                Process.exit Process.self, error
            end

          { :error, _ } = error ->
            Process.exit Process.self, error
        end

        run(master, listener)
      end

      def accept(Listener[socket: socket]) do
        socket |> Socket.accept(automatic: false)
      end

      defoverridable accept: 1

      def start(conn) do
        { :ok, Process.spawn fn ->
          Reagent.wait

          handle(conn)
        end }
      end

      defoverridable start: 1

      def handle(conn) do
        nil
      end

      defoverridable handle: 1
    end
  end

  @doc """
  Accept a client connection from the listener.
  """
  defcallback accept(Listener.t) :: { :ok, Socket.t } | { :error, term }

  @doc """
  Start the process that will handle the connection, either define this or `handle/1`.
  """
  defcallback start(Connection.t) :: { :ok, pid } | { :error, term }

  @doc """
  Handle the connection, either define this or `start/1`.
  """
  defcallback handle(Connection.t) :: :ok | { :error, term }
end
