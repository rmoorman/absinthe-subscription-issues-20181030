defmodule PlateSlateWeb.GraphQL.CreateMenuItemTest do

  use PlateSlateWeb.ConnCase, async: true

  import Ecto.Query

  alias PlateSlate.{Repo, Menu}
  alias PlateSlate.TestAccountsFactory

  @api "/api/graphql"

  setup do
    PlateSlate.TestSeeds.run()

    category_id =
      from(t in Menu.Category, where: t.name == "Sandwiches")
      |> Repo.one!
      |> Map.fetch!(:id)
      |> to_string

    dish_id =
      from(t in Menu.Item, where: t.name == "Water")
      |> Repo.one!
      |> Map.fetch!(:id)
      |> to_string

    {:ok,
      category_id: category_id,
      dish_id: dish_id,
    }
  end


  @query """
  mutation ($menuItem: CreateMenuItemInput!) {
    createMenuItem(input: $menuItem) {
      menuItem {
        name
        description
        price
      }
      errors {
        key
        message
      }
    }
  }
  """

  test "createMenuItem field creates an item", %{category_id: category_id} do
    menu_item = %{
      "name" => "French Dip",
      "description" => "Roast beef, caramelized onions, horseradish, ...",
      "price" => "5.75",
      "categoryId" => category_id,
    }
    user = TestAccountsFactory.create_user("employee")

    conn =
      build_conn()
      |> auth_user(user)
      |> post(@api, query: @query, variables: %{"menuItem" => menu_item})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createMenuItem" => %{
          "menuItem" => %{
            "name" => menu_item["name"],
            "description" => menu_item["description"],
            "price" => menu_item["price"],
          },
          "errors" => nil,
        }
      }
    }
  end

  test "creating a menu item with an existing name fails", %{category_id: category_id} do
    menu_item = %{
      "name" => "Reuben",
      "description" => "Roast beef, caramelized onions, horseradish, ...",
      "price" => "5.75",
      "categoryId" => category_id,
    }
    user = TestAccountsFactory.create_user("employee")

    conn =
      build_conn()
      |> auth_user(user)
      |> post(@api, query: @query, variables: %{"menuItem" => menu_item})

    assert json_response(conn, 200) == %{
      "data" => %{
        "createMenuItem" => %{
          "menuItem" => nil,
          "errors" => [
            %{"key" => "name", "message" => "has already been taken"},
          ],
        },
      },
    }
  end



  @query """
  mutation ($id: ID!, $menuItem: UpdateMenuItemInput!) {
    updateMenuItem(id: $id, input: $menuItem) {
      menuItem { name }
      errors { key message }
    }
  }
  """

  test "updating a menu item succeeds", %{dish_id: dish_id} do
    new_name = "actually h2o"

    conn = post(build_conn(), @api, query: @query, variables: %{
      "id" => dish_id,
      "menuItem" => %{"name" => new_name},
    })

    assert json_response(conn, 200) == %{
      "data" => %{
        "updateMenuItem" => %{
          "menuItem" => %{
            "name" => new_name,
          },
          "errors" => nil,
        },
      },
    }
  end

  test "updating a non existant menu item fails" do
    new_name = "actually h2o"

    conn = post(build_conn(), @api, query: @query, variables: %{
      "id" => -999,
      "menuItem" => %{"name" => new_name},
    })

    assert json_response(conn, 200) == %{
      "data" => %{
        "updateMenuItem" => %{
          "menuItem" => nil,
          "errors" => [
            %{"key" => "", "message" => "invalid item"}
          ],
        },
      },
    }
  end

end
