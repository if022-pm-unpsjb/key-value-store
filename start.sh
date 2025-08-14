docker run -it --rm -v /home/fep/src/elixir/key_value_store:/app -w /app -u 1000:1000 --network host elixir:alpine iex -S mix
