#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defrecord Reagent.Listener, socket: nil, id: nil, pool: nil, module: nil, address: nil, port: nil, secure: nil, acceptors: 1, options: [], env: nil do
  @doc """
  Check if the connection is secure or not.
  """
  @spec secure?(t) :: boolean
  def secure?(__MODULE__[secure: nil]), do: false
  def secure?(__MODULE__[]),            do: true

  @doc """
  Get the certificate of the listener.
  """
  @spec cert(t) :: String.t
  def cert(__MODULE__[secure: nil]), do: nil
  def cert(__MODULE__[secure: sec]), do: sec[:cert]

  @doc """
  Convert the listener to `Socket.options` compatible options.
  """
  @spec to_options(t) :: Keyword.t
  def to_options(__MODULE__[address: address, options: options, secure: nil]) do
    Keyword.merge(options, local: [address: address], automatic: false)
  end

  def to_options(__MODULE__[address: address, options: options, secure: secure]) do
    Keyword.merge(secure, options) |> Keyword.merge(local: [address: address], automatic: false)
  end
end
