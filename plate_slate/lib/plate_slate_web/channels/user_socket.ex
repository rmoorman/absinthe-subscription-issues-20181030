defmodule PlateSlateWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: PlateSlateWeb.GraphQL.Schema

  ## Channels
  # channel "room:*", PlateSlateWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket, _connect_info) do
    socket = with(
      "Bearer " <> token <- Map.get(params, "Authorization"),
      {:ok, data} <- PlateSlateWeb.Authentication.verify(token),
      %{} = user <- get_user(data)
    ) do
      Absinthe.Phoenix.Socket.put_options(socket, context: %{
        current_user: user
      })
    else
      _ -> socket
    end

    {:ok, socket}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     PlateSlateWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil


  defp get_user(%{id: id, role: role}) do
    PlateSlate.Accounts.lookup(role, id)
  end
end