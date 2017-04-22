#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent.Behaviour do
  alias Reagent.Listener
  alias Reagent.Connection

  @doc """
  Accept a client connection from the listener.
  """
  @callback accept(Listener.t) :: { :ok, Socket.t } | { :error, term }

  @doc """
  Start the process that will handle the connection, either define this or `handle/1`.
  """
  @callback start(Connection.t) :: :ok | { :ok, pid } | { :error, term }

  @doc """
  Handle the connection, either define this or `start/1`.
  """
  @callback handle(Connection.t) :: :ok | { :error, term }

  @doc false
  def start_link(pool, listener) do
    Kernel.spawn_link __MODULE__, :run, [pool, listener]
  end

  @doc """
  Uses the reagent behaviour and defines the default callbacks.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      def accept(listener) do
        listener.socket |> Socket.accept
      end

      defoverridable accept: 1

      def start(conn) do
        {:ok, self()}
      end

      defoverridable start: 1

      def handle(conn) do
        nil
      end

      defoverridable handle: 1
    end
  end
end
