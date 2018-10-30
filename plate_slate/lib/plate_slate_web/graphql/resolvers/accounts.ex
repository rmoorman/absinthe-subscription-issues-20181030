defmodule PlateSlateWeb.GraphQL.Resolvers.Accounts do

  alias PlateSlate.Accounts
  alias PlateSlate.Ordering

  def login(_, %{email: email, password: password, role: role}, _) do
    case Accounts.authenticate(role, email, password) do
      {:ok, user} ->
        token = PlateSlateWeb.Authentication.sign(%{
          role: role, id: user.id
        })
        {:ok, %{token: token, user: user}}
      _ ->
        {:error, "incorrect email or password"}
    end
  end

  def me(_, _, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end

  def me(_parent, _args, _resolution) do
    {:ok, nil}
  end

  def orders_for_customer(customer, _args, _resolution) do
    orders = Ordering.orders_for_customer(customer.id)
    {:ok, orders}
  end

end
