defmodule PlateSlateWeb.GraphQL.Plug do
  use Plug.Builder

  plug Absinthe.Plug, [
    schema: PlateSlateWeb.GraphQL.Schema,
    json_codec: Jason,
  ]
end
