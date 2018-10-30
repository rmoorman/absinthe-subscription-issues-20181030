defmodule PlateSlateWeb.SubscriptionCase do
  @moduledoc """
  This module defines the test case to be used by
  subscription tests
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with channels
      use PlateSlateWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest,
        schema: PlateSlateWeb.GraphQL.Schema

      setup do
        PlateSlate.TestSeeds.run()

        {:ok, socket} = Phoenix.ChannelTest.connect(PlateSlateWeb.UserSocket, %{})
        {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

        {:ok, socket: socket}
      end

      import unquote(__MODULE__), only: [menu_item: 1]
    end
  end

  def menu_item(name) do
    PlateSlate.Menu.Item
    |> PlateSlate.Repo.get_by!(name: name)
  end
end
