defmodule PlateSlateWeb.GraphQL.Schema do

  use Absinthe.Schema

  import_types __MODULE__.CommonTypes
  import_types __MODULE__.MenuTypes
  import_types __MODULE__.OrderingTypes
  import_types __MODULE__.AccountsTypes

  alias PlateSlateWeb.GraphQL.Middleware

  ### Apply (common) middleware

  def middleware(middleware, field, %{identifier: :allergy_info} = object) do
    new_middleware = {Absinthe.Middleware.MapGet, to_string(field.identifier)}
    Absinthe.Schema.replace_default(middleware, new_middleware, field, object)
  end

  def middleware(middleware, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  ###
  ### Queries
  ###

  query do
    import_fields :menu_queries
    import_fields :accounts_queries

    @desc "Email filtering"
    field :accept_only_valid_email_list, list_of(:email) do
      arg :email_list, non_null(list_of(:email))
      resolve fn _, args, _ -> {:ok, args.email_list} end
    end
  end

  ###
  ### Mutations
  ###

  mutation do
    import_fields :menu_mutations
    import_fields :ordering_mutations
    import_fields :accounts_mutations
  end

  ###
  ### Subscriptions
  ###

  subscription do
    import_fields :ordering_subscriptions
  end

end
