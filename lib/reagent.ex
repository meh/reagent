#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Reagent do
  @doc """
  Uses the reagent behaviour and defines the default callbacks.
  """
  defmacro __using__(_opts) do
    quote location: :keep do
      use Reagent.Behaviour
    end
  end

  @doc """
  Start a listener with the given module and the given descriptor.
  """
  @spec start(module, Keyword.t) :: { :ok, pid } | { :error, term }
  def start(module, descriptor) do
    start(Keyword.merge(descriptor, module: module))
  end

  @doc """
  Start a listener with the given descriptor.
  """
  @spec start(Keyword.t) :: { :ok, pid } | { :error, term }
  def start(descriptor) do
    Reagent.Listener.start(descriptor)
  end

  @doc """
  Start a listener with the given module and the given descriptor and link the
  process.
  """
  @spec start_link(module, Keyword.t) :: { :ok, pid } | { :error, term }
  def start_link(module, descriptor) do
    start_link(Keyword.merge(descriptor, module: module))
  end

  @doc """
  Start a listener with the given descriptor and link the process.
  """
  @spec start_link(Keyword.t) :: { :ok, pid } | { :error, term }
  def start_link(descriptor) do
    Reagent.Listener.start_link(descriptor)
  end

  @doc """
  Wait for the accept ack.
  """
  @spec wait(timeout) :: :ok | { :timeout, timeout }
  def wait(timeout \\ :infinity) do
    receive do
      { Reagent, :ack } ->
        :ok
    after timeout ->
      { :timeout, timeout }
    end
  end
end
