defmodule PlateSlateWeb.GraphQL.QueryMenuItemsTest do

  use PlateSlateWeb.ConnCase, async: true


  @api "/api/graphql"


  setup do
    PlateSlate.TestSeeds.run()
  end


  @query """
  {
    menuItems(filter: {}) {
      name
    }
  }
  """
  test "menuItems field returns menu items" do
    conn = build_conn()
    conn = get(conn, @api, query: @query)

    assert json_response(conn, 200) == %{
      "data" => %{
        "menuItems" => [
          %{"name" => "Bánh mì"},
          %{"name" => "Chocolate Milkshake"},
          %{"name" => "Croque Monsieur"},
          %{"name" => "French Fries"},
          %{"name" => "Lemonade"},
          %{"name" => "Masala Chai"},
          %{"name" => "Muffuletta"},
          %{"name" => "Papadum"},
          %{"name" => "Pasta Salad"},
          %{"name" => "Reuben"},
          %{"name" => "Soft Drink"},
          %{"name" => "Vada Pav"},
          %{"name" => "Vanilla Milkshake"},
          %{"name" => "Water"},
        ]
      }
    }
  end


  @query """
  {
    menuItems(filter: {}, order: DESC) {
      name
    }
  }
  """
  test "menuItems field returns items descending using literals" do
    response = get(build_conn(), @api, query: @query)
    assert %{
      "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
    } = json_response(response, 200)
  end


  @query """
  query ($order: SortOrder!) {
    menuItems(filter: {}, order: $order) {
      name
    }
  }
  """
  @variables %{"order" => "DESC"}
  test "menuItems field returns items descending using variables" do
    response = get(build_conn(), @api, query: @query, variables: @variables)
    assert %{
      "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
    } = json_response(response, 200)
  end


  @query """
  query ($term: String) {
    menuItems(filter: {name: $term}) {
      name
    }
  }
  """
  @variables %{"term" => "reu"}
  test "menuItems field returns menu items filtered by name" do
    conn = get(build_conn(), @api, query: @query, variables: @variables)
    assert json_response(conn, 200) == %{
      "data" => %{
        "menuItems" => [
          %{"name" => "Reuben"},
        ]
      }
    }
  end


  @query """
  query ($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{filter: %{"tag" => "Vegetarian", "category" => "Sandwiches"}}
  test "menuItems field returns menuItems, filtering with a variable" do
    response = get(build_conn(), @api, query: @query, variables: @variables)
    assert %{
      "data" => %{"menuItems" => [%{"name" => "Vada Pav"}]}
    } == json_response(response, 200)
  end


  @query """
  query ($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
      addedOn
    }
  }
  """
  @variables %{filter: %{"addedBefore" => "2017-01-20"}}
  test "menuItems filtered by custom scalar" do
    sides = PlateSlate.Repo.get_by!(PlateSlate.Menu.Category, name: "Sides")
    %PlateSlate.Menu.Item{
      name: "Garlic Fries",
      added_on: ~D[2017-01-01],
      price: 2.50,
      category: sides
    } |> PlateSlate.Repo.insert!
    response = get(build_conn(), @api, query: @query, variables: @variables)
    assert %{
      "data" => %{
        "menuItems" => [%{"name" => "Garlic Fries", "addedOn" => "2017-01-01"}]
      }
    } == json_response(response, 200)
  end


  @query """
  query ($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{filter: %{"addedBefore" => "not-a-date"}}
  test "menuItems filtered by custom scalar with error" do
    response = get(build_conn(), @api, query: @query, variables: @variables)

    assert %{"errors" => [%{"locations" => [
      %{"column" => 0, "line" => 2}], "message" => message}]} = json_response(response, 200)

    expected = """
    Argument "filter" has invalid value $filter.
    In field "addedBefore": Expected type "Date", found "not-a-date".\
    """
    assert expected == message
  end


  @query """
  query ($filter: String!, $order: SortOrder!) {
    categoryList(name: $filter, order: $order) {
      name
    }
  }
  """
  @variables %{filter: "i", order: "DESC"}
  test "categoryList filtered by name and ordered descending" do
    response = get(build_conn(), @api, query: @query, variables: @variables)

    assert %{"data" => %{
      "categoryList" => [
        %{"name" => "Sides"},
        %{"name" => "Sandwiches"},
      ]
    }} == json_response(response, 200)
  end

  @query """
  query ($emailList: [Email]) {
    acceptOnlyValidEmailList(emailList: $emailList)
  }
  """
  test "acceptOnlyValidEmailList field return the list of given email adresses when they seem correct" do
    variables = %{emailList: ["something"]}
    response = get(build_conn(), @api, query: @query, variables: variables)

    assert %{
      "errors" => [
        %{"locations" => [%{"column" => 0, "line" => 2}], "message" => message}
      ]
    } = json_response(response, 200)

    assert ^message = """
    Argument "emailList" has invalid value $emailList.
    In element #1: Expected type "Email", found "something".\
    """

    variables = %{emailList: ["foo@example.com", "bar@example.com"]}
    response = get(build_conn(), @api, query: @query, variables: variables)

    assert %{
      "data" => %{
        "acceptOnlyValidEmailList" => [
          "foo@example.com",
          "bar@example.com",
        ]
      }
    } == json_response(response, 200)
  end
end
