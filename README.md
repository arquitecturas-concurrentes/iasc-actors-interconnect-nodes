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