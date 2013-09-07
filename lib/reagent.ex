defmodule Reagent do
  def start(module, options) do
    :gen_server.start(Reagent.Master, [module, options], [])
  end

  def start_link(module, options) do
    :gen_server.start_link(Reagent.Master, [module, options], [])
  end

  def wait(timeout // :infinity) do
    receive do
      { Reagent, :ack } ->
        :ok
    after
      timeout ->
        { :timeout, timeout }
    end
  end
end
