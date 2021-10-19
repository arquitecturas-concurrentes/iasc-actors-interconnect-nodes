# Interconectar nodos en Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `interconnect_nodes` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:interconnect_nodes, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/interconnect_nodes>.

## Objetivo

- Mostrar como interconectar nodos sin uso de una libreria adicional.
- Conexion de nodos de ELixir en una misma red de manera manual
- Cookies de los nodos en Elixir
- Nociones de EPMD

## Descripcion

Interconectar nodos en Elixir es simple, y el runtime ya provee los mecanismos para poder interconectar varios nodos de Elixir en la red, sin mayores problemas.

```elixir
iex --sname a --cookie secret_token -S mix
```

```elixir
iex --sname b --cookie another_secret
```

```elixir
iex --sname b --cookie secret_token 
```

Ahora podemos ver que si tratamos de ver que nodo somos en la nueav consola incializada, vemos que estamos en el nodo `b`:

```elixir
iex(b@altair)1> Node.self
:b@altair
```

```
iex(b@altair)4> Node.get_cookie
:secret_token
```

vemos que si queremos ver si podemos interconectar el nodo b con el `c`, como tienen distinta cookie, no se pueden interconectar

```elixir
iex(b@altair)5> :net_adm.ping(:c@altair)   
:pang
```

... pero en cambio si lo hacemos contra el `nodo a`, con el que si tenemos la misma cookie, y existe ademas, podemos ver que en principio, se podrian interconectar entre si.

```elixir
iex(b@altair)6> :net_adm.ping(:a@altair) 
:pong
```


Podemos interconectar los nodos de manera manual, de la siguiente manera (desde el nodo b):

```elixir
Node.connect :a@altair
```

Esto permite conectar dos nodos, ahora si levantamos un tercer nodo y tratamos de conectarnos

```bash
iex --sname c 
```

```elixir
iex(c@altair)1> Node.connect :a@altair
false
```

Ademas, en el nodo contra el que no se pudo conectar, podemos llegar a tener algun warning del evento que acaba de fallar:

```
17:02:24.120 [error] ** Connection attempt from node :c@altair rejected. Invalid challenge reply. **
```

Ahora, no podemos, mas que nada porque no tiene la misma cookie el `nodo c` que los otros dos, por lo cual tendriamos que eventualmente setear la cookie a un valor que sea similar al de los nodos contra los que queremos comunicarnos:

```elixir
Node.set_cookie :secret_token
```

ahora viendo desde el `nodo a`, a los nodos que tiene conectados, podemos ver a los `nodos b y c`:

```elixir
iex(a@altair)5> Node.list 
[:b@altair, :c@altair]
```

Ahora solo flata ver, como podemos llamar desde b al proceso PingPong supervisado que esta en el `nodo a`:


```elixir
iex(b@altair)14> GenServer.call({PingPong, :a@altair}, :ping)  
:pong
```

## Interconectando Nodos con sys.config

La idea de interconectar los nodos de manera manual, tal vez no es la mejor, por lo que se puede optar por la de utilizar un archivo de configuracion [sys.config](https://erlang.org/doc/man/config.html), que nos permita definir los nodos que se levantaran y el timeout para que se interconecten los nodos. Hay que tener en cuenta que la sintaxis que hay que usar en este tipo de archivos es de elang y no de Elixir.

```erlang
[{kernel,
  
    {sync_nodes_optional, ['a@127.0.0.1', 'b@127.0.0.1']},
    {sync_nodes_timeout, 5000}
  ]}
].
```

Este archivo de configuracion setea valores por default, cuando se inicializa el nodo, en este caso, cada vez que inicialicemos un nodo aplicando esta configuracion, agregaremos dos opciones:

- sync_nodes_optional: La lista de posibles nodos en el cluster.
- sync_nodes_timeout: El timeout para poder sincronizar los nodos.

Ahora para aplicar esta configuracion cuando inicializamos, habra que pasarle la opcion `erl` cuando inicializamos el nodo:

```bash
iex --name a@127.0.0.1 --erl "-config sys.config" -S mix
```

y el segundo nodo de la siguiente manera

```bash
iex --name b@127.0.0.1 --erl "-config sys.config" -S mix
```

Ahora una vez que esta incializado, vamos a poder que los nodos se interconectan solos y sin mayor interaccion entre ellos:

```elixir
iex(a@127.0.0.1)1> Node.list
[:"b@127.0.0.1"]
```

## Monitoreando los nodos conectados/desconectados del cluster

Se puede llegar a saber cuando exactamente sucede que un nodo de conecta o se desconecta de un cluster. Esto nos puede llegar a ser particularmente util cuando queremos monitorear este tipo de eventos, sea para loggearlo o bien hacer alguna accion frente a ello. Para lograr esto, hay que usar la funcion del modulo de `:net_kernel`, que esta definido en el kernel de Erlang. La funcion que nos permite monitorear desde un proceso estos eventos es `monitor_nodes\1`. Mas de esto en la [documentacion](https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1).

Podemos llamando a la funcion `:net_kernel.monitor_nodes(true)`, que el proceso que lo llame, monitoree la conexion/desconexion de nodos. Un ejemplo simple lo podemos ver en este repo y podemos llamarlo `ClusterObserver`. La idea es que sea un Genserver, que actue como listener de estos eventos, y se suscriba a estos, usando la funcion `monitor_nodes\1`


```elixir
defmodule Cluster.Observer do
  use GenServer
  require Logger

  def start_link(_)do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    # https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1
    :net_kernel.monitor_nodes(true)

    {:ok, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has left the cluster.
  """
  def handle_info({:nodedown, node}, state) do
    Logger.info("--- Node down: #{node}")

    {:noreply, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has joined the cluster.
  """
  def handle_info({:nodeup, node}, state) do
    Logger.info("--- Node up: #{node}")

    {:noreply, state}
  end
end
```
