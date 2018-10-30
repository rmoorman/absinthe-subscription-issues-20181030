defmodule PlateSlateWeb.Plug.Context do

  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    with(
      ["Bearer " <> token] <- get_req_header(conn, "authorization"),
      {:ok, data} <- PlateSlateWeb.Authentication.verify(token),
      %{} = user <- get_user(data)
    ) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  defp get_user(%{id: id, role: role}) do
    PlateSlate.Accounts.lookup(role, id)
  end

end
