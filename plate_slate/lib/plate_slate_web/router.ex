defmodule PlateSlateWeb.Router do
  use PlateSlateWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug PlateSlateWeb.Plug.Context
  end

  scope "/", PlateSlateWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/api" do
    pipe_through :api
    forward "/graphql", PlateSlateWeb.GraphQL.Plug
    forward "/graphiql", PlateSlateWeb.GraphQL.GraphiQL.Simple
    forward "/graphiql-advanced", PlateSlateWeb.GraphQL.GraphiQL.Advanced
    forward "/graphiql-playground", PlateSlateWeb.GraphQL.GraphiQL.Playground
  end
end
