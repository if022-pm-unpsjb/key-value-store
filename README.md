# Key Value Store

Ejemplo de almacen clave-valor

## Ejecución

Con Docker:
```
$ docker run -it --rm -v $(pwd):/app -w /app --network host elixir:alpine iex -S mix
```

## Único servidor

El modulo `KeyValueStore` implementa el almacen en un único servidor:
```
iex> KeyValueStore.start_link
{:ok, #PID<0.128.0>}
iex> KeyValueStore.put(:nombre, "Mafalda")
:ok
iex> KeyValueStore.get(:nombre)
"Mafalda"
iex>
```

## Replicado

El modulo `KeyValueStoreReplicated` implementa el almacen mediante un grupo de procesos, con un primario y replicas:
```
iex> KeyValueStoreReplicated.start_link
{:ok, #PID<0.128.0>}
iex> KeyValueStoreReplicated.start_link(:slave1)
{:ok, #PID<0.129.0>}
iex> KeyValueStoreReplicated.start_link(:slave2)
{:ok, #PID<0.130.0>}
iex> KeyValueStoreReplicated.add_slave(:slave1)
:ok
iex> KeyValueStoreReplicated.add_slave(:slave2)
:ok
iex> KeyValueStoreReplicated.put(:nombre, "Mafalda")
:ok
iex> KeyValueStoreReplicated.get(:nombre)
"Mafalda"
iex> GenServer.call(:slave1, {:get, :nombre})
"Mafalda"
```

## Distribuido

El modulo `KeyValueStoreReplicated` implementa el almacen mediante un grupo de procesos, con un primario y replicas, pero que pueden ejecutarse en distintos nodos fisicos:

Ejecutar los nodos añadiendo las opciones `name` y `cookie`. Por ejemplo, suponer que se crea un master y un slave:
```
$ docker run -it --rm -v $(pwd):/app -w /app --network host elixir:alpine iex --sname master --cookie secret -S mix
```
```
$ docker run -it --rm -v $(pwd):/app -w /app --network host elixir:alpine iex --sname slave1 --cookie secret -S mix
```

En el nodo `slave1` ejecutar:
```
iex> Node.connect(:"master@ip")
:ok
iex> KeyValueStoreDistributed.start_link(:slave1)
{:ok, #PID<0.128.0>}
```

En el nodo `master` ejecutar:
```
iex> KeyValueStoreDistributed.start_link
{:ok, #PID<0.128.0>}
iex> KeyValueStoreDistributed.add_slave(:slave1)
:ok
iex> KeyValueStoreDistributed.put(:nombre, "Mafalda")
:ok
iex> KeyValueStoreDistributed.get(:nombre)
"Mafalda"
```

Luego, nuevamente en el nodo `slave` ejecutar:
```
iex> GenServer.call({:global, :slave1}, {:get, :nombre})
"Mafalda"
```
