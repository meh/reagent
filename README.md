reagent - socket acceptor pool
==============================
**reagent** is a socket acceptor pool for Elixir that leverages the
[socket](https://github.com/meh/elixir-socket) library and its protocols to
provide an easy way to implement servers.

Getting started
---------------
To define a reagent you first have to define a module using the reagent
behaviour. This will define some basic functions you can extend and other
helpers on the module and will make it startable as a reagent.

```elixir
defmodule Test do
  use Reagent.Behaviour
end
```

When you want to start a server running the defined reagent, you have to call
`Reagent.start`. It takes as first parameter the module implementing the
behaviour and as second parameter a list of listener descriptors or a single
listener descriptor.

Listener descriptors contain the definition of the listener, including address,
port, whether it's secure or not and other `:inet.setopts` options.

Reagent behaviour
-----------------
A reagent to do anything useful as to either implement `handle/1` or `start/1`.

`handle/1` is called by the default `start/1` and it gets called as the entry
point of an internally created process. It gets called with a
`Reagent.Connection` record.

This is usually useful to implement simple protocols when you don't need a full
blown `gen_server` or similar to handle a connection.

If you want more complex connection handling you can define `start/1`, it gets
called with a `Reagent.Connection` record as well and must return `{ :ok, pid
}` or `{ :error, reason }`. The returned process will be made owner of the
socket and be used as reference for the connection itself.

You can also define `accept/1` which gets called with the `Reagent.Listener`
and allows you more fine grained socket acception.

Simple example
--------------
```elixir
defmodule Echo do
  use Reagent.Behaviour

  def handle(conn) do
    case conn |> Socket.Stream.recv! do
      nil ->
        :closed

      data ->
        conn |> Socket.Stream.send! data

        handle(conn)
    end
  end
end
```

This is a simple implementation of an echo server.

To start it on port 8080 just run `Reagent.start Echo, port: 8080`.

Complex example
---------------
```elixir
defmodule Echo do
  defmodule Client do
    use GenServer.Behaviour

    def init(connection) do
      { :ok, connection }
    end

    # this message is sent when the socket has been completely accepted and the
    # process has been made owner of the socket, you don't need to wait for it
    # when implementing handle because it's internally handled
    def handle_info({ Reagent, :ack }, connection) do
      connection |> Socket.active!

      { :noreply, connection }
    end

    def handle_info({ :tcp, _, data }, connection) do
      connection |> Socket.Stream.send! data

      { :noreply, connection }
    end

    def handle_info({ :tcp_closed, _ }, _connection) do
      { :stop, :normal, _connection }
    end
  end

  use Reagent.Behaviour

  def start(connection) do
    :gen_server.start(Client, connection, [])
  end
end
```

This is the implementation of a full-blown `gen_server` based echo server
(which is obviously overkill).

As with the simple example you just start it with `Reagent.start Echo, port:
8080`.
