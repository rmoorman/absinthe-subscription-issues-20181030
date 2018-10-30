defmodule PlateSlateWeb.GraphQL.Subscription.NewOrderTest do

  use PlateSlateWeb.SubscriptionCase

  alias PlateSlate.TestAccountsFactory

  @subscription """
  subscription {
    newOrder { customerNumber }
  }
  """
  @mutation """
  mutation ($input: PlaceOrderInput!) {
    placeOrder(input: $input) { order { id } }
  }
  """
  @login """
  mutation ($email: String!, $role: Role!, $password: String!) {
    login(role: $role, email: $email, password: $password) {
      token
    }
  }
  """
  #@tag :skip
  test "new orders can be subscribed to", %{socket: socket} do
    # login
    user = TestAccountsFactory.create_user("employee")
    ref = push_doc socket, @login, variables: %{
      "email" => user.email,
      "role" => "EMPLOYEE",
      "password" => "super-secret",
    }
    assert_reply ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000

    # setup a subscription
    ref = push_doc socket, @subscription
    assert_reply ref, :ok, %{subscriptionId: subscription_id}

    # run a mutation to trigger the subscription
    order_input = %{
      "customerNumber" => 24,
      "items" => [
        %{"menuItemId" => menu_item("Reuben").id, "quantity" => 2},
      ]
    }
    ref = push_doc socket, @mutation, variables: %{"input" => order_input}
    assert_reply ref, :ok, reply
    assert %{data: %{"placeOrder" => %{"order" => %{"id" => _}}}} = reply

    # check to see if we got subscription data
    expected = %{
      result: %{data: %{"newOrder" => %{"customerNumber" => 24}}},
      subscriptionId: subscription_id,
    }
    assert_push "subscription:data", push
    assert expected == push
  end




  test "customers can't see other customers orders", %{socket: socket} do
    customer1 = TestAccountsFactory.create_user("customer")

    # login as customer1
    ref = push_doc socket, @login, variables: %{
      "email" => customer1.email,
      "role" => "CUSTOMER",
      "password" => "super-secret",
    }
    assert_reply ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000

    # subscribe customer1 to orders
    ref = push_doc socket, @subscription
    assert_reply ref, :ok, %{subscriptionId: _subscription_id}

    # customer1 places order
    place_order(customer1)
    assert_push "subscription:data", _

    # customer2 places order
    customer2 = TestAccountsFactory.create_user("customer")
    place_order(customer2)
    refute_receive _
  end


  defp place_order(customer) do
    order_input = %{
      "customerNumber" => customer.id,
      "items" => [%{"quantity" => 2, "menuItemId" => menu_item("Reuben").id}]
    }
    {:ok, %{data: %{"placeOrder" => _}}} = Absinthe.run(
      @mutation,
      PlateSlateWeb.GraphQL.Schema,
      [
        context: %{current_user: customer},
        variables: %{"input" => order_input},
      ]
    )
  end
end
