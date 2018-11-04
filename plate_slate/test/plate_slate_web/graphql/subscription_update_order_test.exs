defmodule PlateSlateWeb.GraphQL.Subscription.UpdateOrderTest do

  use PlateSlateWeb.SubscriptionCase

  alias PlateSlate.TestAccountsFactory

  @subscription """
  subscription ($id: ID!) {
    updateOrder(id: $id) {
      state
    }
  }
  """

  @ready_order_mutation """
  mutation ($id: ID!) {
    readyOrder(id: $id) {
      errors{message}
    }
  }
  """

  @complete_order_mutation """
  mutation ($id: ID!) {
    completeOrder(id: $id) {
      errors{message}
    }
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
  test "subscribe to order updates", %{socket: socket} do
    # login
    user = TestAccountsFactory.create_user("employee")
    ref = push_doc socket, @login, variables: %{
      "email" => user.email,
      "role" => "EMPLOYEE",
      "password" => "super-secret",
    }
    assert_reply ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000

    reuben = menu_item("Reuben")

    {:ok, order1} = PlateSlate.Ordering.create_order(%{
      customer_number: 123,
      items: [%{menu_item_id: reuben.id, quantity: 2}]
    })

    {:ok, order2} = PlateSlate.Ordering.create_order(%{
      customer_number: 124,
      items: [%{menu_item_id: reuben.id, quantity: 1}]
    })

    ref = push_doc(socket, @subscription, variables: %{"id" => order1.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref1}

    ref = push_doc(socket, @subscription, variables: %{"id" => order2.id})
    assert_reply ref, :ok, %{subscriptionId: subscription_ref2}

    ref = push_doc(socket, @ready_order_mutation, variables: %{"id" => order2.id})
    assert_reply ref, :ok, reply

    refute reply[:errors]
    refute reply[:data]["readyOrder"]["errors"]

    assert_push "subscription:data", push
    expected = %{
      result: %{data: %{"updateOrder" => %{"state" => "ready"}}},
      subscriptionId: subscription_ref2,
    }
    assert expected == push
  end



  test "customers can't see ready updates to other customer's orders", %{socket: socket} do
    customer = TestAccountsFactory.create_user("customer")
    employee = TestAccountsFactory.create_user("employee")
    reuben = menu_item("Reuben")

    # login as customer
    ref = push_doc socket, @login, variables: %{
      "email" => customer.email,
      "role" => "CUSTOMER",
      "password" => "super-secret",
    }
    assert_reply ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000

    # Create an order for another customer and subscribe the customer
    # to it's updates. Also create another order, this time for the
    # customer at hand and subscribe to it's updates.
    # Note that subscription ought to succeed but won't actually
    # deliver any data to unwanted subscribers.
    {:ok, order1} = PlateSlate.Ordering.create_order(%{
      customer_number: customer.id + 10,
      items: [%{menu_item_id: reuben.id, quantity: 2}]
    })

    {:ok, order2} = PlateSlate.Ordering.create_order(%{
      customer_number: customer.id,
      items: [%{menu_item_id: reuben.id, quantity: 1}]
    })

    ref = push_doc(socket, @subscription, variables: %{"id" => order1.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref1}

    ref = push_doc(socket, @subscription, variables: %{"id" => order2.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref2}

    ready_order(order1, employee)
    refute_receive _

    ready_order(order2, employee)
    assert_push "subscription:data", _
  end



  test "customers can't see completion updates to other customer's orders", %{socket: socket} do
    customer = TestAccountsFactory.create_user("customer")
    employee = TestAccountsFactory.create_user("employee")
    reuben = menu_item("Reuben")

    # login as customer
    ref = push_doc socket, @login, variables: %{
      "email" => customer.email,
      "role" => "CUSTOMER",
      "password" => "super-secret",
    }
    assert_reply ref, :ok, %{data: %{"login" => %{"token" => _}}}, 1_000

    # Create an order for another customer and subscribe the customer
    # to it's updates. Also create another order, this time for the
    # customer at hand and subscribe to it's updates.
    # Note that subscription ought to succeed but won't actually
    # deliver any data to unwanted subscribers.
    {:ok, order1} = PlateSlate.Ordering.create_order(%{
      customer_number: customer.id + 10,
      items: [%{menu_item_id: reuben.id, quantity: 2}]
    })

    {:ok, order2} = PlateSlate.Ordering.create_order(%{
      customer_number: customer.id,
      items: [%{menu_item_id: reuben.id, quantity: 1}]
    })

    ref = push_doc(socket, @subscription, variables: %{"id" => order1.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref1}

    ref = push_doc(socket, @subscription, variables: %{"id" => order2.id})
    assert_reply ref, :ok, %{subscriptionId: _subscription_ref2}

    complete_order(order1, employee)
    refute_receive _

    complete_order(order2, employee)
    assert_push "subscription:data", _
  end



  defp ready_order(order, employee) do
    Absinthe.run(
      @ready_order_mutation,
      PlateSlateWeb.GraphQL.Schema,
      [
        context: %{current_user: employee, pubsub: PlateSlateWeb.Endpoint},
        variables: %{"id" => order.id}
      ]
    )
  end

  defp complete_order(order, employee) do
    Absinthe.run(
      @complete_order_mutation,
      PlateSlateWeb.GraphQL.Schema,
      [
        context: %{current_user: employee, pubsub: PlateSlateWeb.Endpoint},
        variables: %{"id" => order.id}
      ]
    )
  end

end
