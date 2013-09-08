defmodule Reagent do
  def start(module, details // nil, listeners) do
    :gen_server.start(Reagent.Master, [module, details, listeners], [])
  end

  def start_link(module, details // nil, listeners) do
    :gen_server.start_link(Reagent.Master, [module, details, listeners], [])
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
