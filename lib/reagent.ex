#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.


# raw: 9213
# ranch: 8504
# reagent: 5377

defmodule Reagent do
  def start(module, descriptor) do
    start(Keyword.merge(descriptor, module: module))
  end

  def start(descriptor) do
    Reagent.Listener.start(descriptor)
  end

  def start_link(module, descriptor) do
    start_link(Keyword.merge(descriptor, module: module))
  end

  def start_link(descriptor) do
    Reagent.Listener.start_link(descriptor)
  end

  def wait(timeout // :infinity) do
    receive do
      { Reagent, :ack } ->
        :ok
    after timeout ->
      { :timeout, timeout }
    end
  end
end
