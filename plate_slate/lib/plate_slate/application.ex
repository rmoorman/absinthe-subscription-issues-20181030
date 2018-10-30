defmodule PlateSlate.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      PlateSlate.Repo,
      PlateSlateWeb.Endpoint,

      # We could use:
      # {Absinthe.Subscription, [PlateSlateWeb.Endpoint]}
      #
      # But we are not on master :D
      # https://github.com/absinthe-graphql/absinthe/issues/617
      %{
        id: Absinthe.Subscription,
        start: {Absinthe.Subscription, :start_link, [PlateSlateWeb.Endpoint]}
      }

    ]

    opts = [strategy: :one_for_one, name: PlateSlate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PlateSlateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
