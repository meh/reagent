#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Behaviour do
  use Behaviour

  alias Reagent.Listener
  alias Reagent.Connection

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

  @doc false
  def start_link(pool, Listener[module: module] = listener) do
    Process.spawn_link __MODULE__, :run, [pool, listener]
  end

  @doc false
  def run(pool, Listener[module: module] = listener) do
    # wait for the max connections limit to be fulfilled
    :gen_server.call(pool, { :wait, listener }, :infinity)

    case module.accept(listener) do
      { :ok, socket } ->
        conn = Connection[id: make_ref, pool: pool, listener: listener, socket: socket]

        case module.start(conn) do
          { :ok, pid } ->
            # if it's linked bad things will happen
            Process.unlink(pid)

            # set the new pid as owner of the socket
            socket |> Socket.process!(pid)

            # tell the pool we accepted a connection so it can start monitoring it
            :gen_server.call pool, { :accepted, conn, pid }

            # send the ack to the pid
            pid <- { Reagent, :ack }

          { :error, _ } = error ->
            exit error
        end

      { :error, _ } = error ->
        exit error
    end

    run(pool, listener)
  end

  @doc """
  Uses the reagent behaviour and defines the default callbacks.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

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
end
