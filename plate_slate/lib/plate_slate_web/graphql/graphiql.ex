# Use plug wrapper workaround for forwarding to same plug multiple times
# see: https://github.com/graphql-elixir/plug_graphql/issues/7

defmodule PlateSlateWeb.GraphQL.GraphiQL do
  defmodule Simple do
    use Plug.Builder
    plug Absinthe.Plug.GraphiQL, [
      schema: PlateSlateWeb.GraphQL.Schema,
      interface: :simple, # :simple | :advanced | :playground,
      json_codec: Jason,
      socket: PlateSlateWeb.UserSocket,
    ]
  end

  defmodule Advanced do
    use Plug.Builder
    plug Absinthe.Plug.GraphiQL, [
      schema: PlateSlateWeb.GraphQL.Schema,
      interface: :advanced, # :simple | :advanced | :playground,
      json_codec: Jason,
      socket: PlateSlateWeb.UserSocket,
    ]
  end

  defmodule Playground do
    use Plug.Builder
    plug Absinthe.Plug.GraphiQL, [
      schema: PlateSlateWeb.GraphQL.Schema,
      interface: :playground, # :simple | :advanced | :playground,
      json_codec: Jason,
      socket: PlateSlateWeb.UserSocket,
    ]
  end
end
