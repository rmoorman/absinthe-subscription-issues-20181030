defmodule PlateSlateWeb.GraphQL.MutationLoginEmployeeTest do

  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.TestAccountsFactory

  @api "/api/graphql"

  @query """
  mutation ($email: String!, $password: String!) {
    login(role: EMPLOYEE, email: $email, password: $password) {
      token
      user {
        name
      }
    }
  }
  """
  test "creating an employee session" do
    user = TestAccountsFactory.create_user("employee")

    response = post(build_conn(), @api, %{
      query: @query,
      variables: %{
        "email" => user.email,
        "password" => "super-secret",
      },
    })

    assert %{"data" => %{"login" => %{
      "token" => token,
      "user" => user_data
    }}} = json_response(response, 200)

    assert %{"name" => user.name} == user_data
    assert {:ok, %{role: :employee, id: user.id}} ==
      PlateSlateWeb.Authentication.verify(token)
  end

end
