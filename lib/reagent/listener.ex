defrecord Reagent.Listener, id: nil, master: nil, socket: nil, address: nil, port: nil, acceptors: 1, secure: nil, options: [], details: nil do
  def secure?(__MODULE__[secure: nil]), do: false
  def secure?(__MODULE__[]),            do: true

  def cert(__MODULE__[secure: nil]), do: nil
  def cert(__MODULE__[secure: sec]), do: sec[:cert]

  def to_options(__MODULE__[address: address, options: options, secure: nil]) do
    Keyword.merge(options, local: [address: address], automatic: false)
  end

  def to_options(__MODULE__[address: address, options: options, secure: secure]) do
    Keyword.merge(secure, options) |> Keyword.merge(local: [address: address], automatic: false)
  end
end
