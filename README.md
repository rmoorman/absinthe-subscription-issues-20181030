# Test instructions

In order to reproduce the issue (within the tests)

~~~~
cd plate_slate
mix deps.get
mix test
~~~~


## What does not seem to work

There are two test cases for subscriptions on order updates, one for marking the
order as ready and one for marking it as complete.

The relevant source for the ready update test lives here
`plate_slate/test/plate_slate_web/graphql/subscription_update_order_test.exs:85`

The source for the complete update test lives in the same file
`plate_slate/test/plate_slate_web/graphql/subscription_update_order_test.exs:128`

In both cases, a customer and employee is created. Then two orders are created
and the customer is subscribed to the `updateOrder` field for both of them.
(The way it is set up here, the subscription should succeed but delivery should
be restricted)

After that, for the ready order test, `Absinthe.run` is used to call the
`readyOrder` mutation with the employee as current user. This succeeds. As can
be seen at `plate_slate/lib/plate_slate_web/graphql/resolvers/ordering.ex:22`,
we publish the subscription manually using `Absinthe.Subscription.publish`.

For the complete order test, `Absinthe.run` is also being used (this time to
call the `completeOrder` mutation). The main difference is here that instead
of manually publishing within the resolver, the `updateOrder` field is
configured to trigger upon `:complete_order` within the schema
(`lib/plate_slate_web/graphql/schema/ordering_types.ex:93`).
This time it doesn't seem to work though, the mailbox stays empty.


## What would be expected

That running the mutation through absinthe run within the tests would
also cause the trigger configuration within the schema to be cause
subscription data to be delivered.



# Testing manually within the advanced graphiql interface

The described problems do not seem to apply to the api running
within the phoenix application and being accessed through graphiql.

## For reference

Setup an employee and a customer
~~~~
iex -S mix

iex(1)> alias PlateSlate.Accounts
iex(2)> %Accounts.User{} |>
Accounts.User.changeset(%{role: "employee", name: "Becca Wilson",
  email: "foo@example.com", password: "abc123"}) |> PlateSlate.Repo.insert!

iex(3)> %Accounts.User{} |>
Accounts.User.changeset(%{role: "customer", name: "Joe Hubert",
  email: "bar@example.com", password: "abc123"}) |> PlateSlate.Repo.insert!
~~~~

Start the server

~~~~
mix phx.server
~~~~

and head over to <http://localhost:4000/api/graphiql-advanced>

Issue a login query for the customer and the employee (noting the tokens)
~~~~
mutation {
  login(email:"bar@example.com", role:CUSTOMER, password:"abc123") {
    token
    user { name }
  }
}

{
  "data": {
    "login": {
      "token": "SFMyNTY.g3QAAAACZAAEZGF0YXQAAAACZAACaWRhAmQABHJvbGVkAAhjdXN0b21lcmQABnNpZ25lZG4GAA3zA8VmAQ.6H3Bn5u9CfwG5FA5OdFJBBPhCH8_6y1hTEGPHYG6QQY",
      "user": {
        "name": "Joe Hubert"
      }
    }
  }
}


mutation {
  login(email:"foo@example.com", role:EMPLOYEE, password:"abc123") {
    token
    user { name }
  }
}

{
  "data": {
    "login": {
      "token": "SFMyNTY.g3QAAAACZAAEZGF0YXQAAAACZAACaWRhAWQABHJvbGVkAAhlbXBsb3llZWQABnNpZ25lZG4GAM4CBsVmAQ.w-OlFSVbCZWHriaiGxPJQbIdwpVNpbnDgZj0jg8R8ZI",
      "user": {
        "name": "Becca Wilson"
      }
    }
  }
}
~~~~

Then Place an order as customer

~~~~
mutation {
  placeOrder(input:{items:[{quantity: 2, menuItemId:"1"}]}) {
    order {
      id
      customerNumber
    }
    errors { key message }
  }
}

{
  "data": {
    "placeOrder": {
      "errors": null,
      "order": {
        "customerNumber": 2,
        "id": "2"
      }
    }
  }
}
~~~~

And subscribe to it's updates (of course as the customer, make sure the Authorization
header is set and change order id of course).

~~~~
subscription {
  updateOrder(id: "2") {
    state
  }
}
~~~~

Then, with a new query and authorized as employee, ready the order

~~~~
mutation {
  readyOrder(id:"2"){
    order{state}
    errors{key message}
  }
}

{
  "data": {
    "readyOrder": {
      "errors": null,
      "order": {
        "state": "ready"
      }
    }
  }
}
~~~~

Which should lead to a subscription update for the customer. So now complete the order.

~~~~
mutation {
  completeOrder(id:"2"){
    order{state}
    errors{key message}
  }
}

{
  "data": {
    "completeOrder": {
      "errors": null,
      "order": {
        "state": "complete"
      }
    }
  }
}
~~~~

And we should see the subscription update too.
