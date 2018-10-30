defmodule PlateSlateWeb.GraphQL.Schema.CommonTypes do

  use Absinthe.Schema.Notation

  enum :sort_order do
    value :asc
    value :desc
  end

  scalar :date do
    parse fn input ->
      with(
        %Absinthe.Blueprint.Input.String{value: value} <- input,
        {:ok, date} <- Date.from_iso8601(value)
      ) do
        {:ok, date}
      else
        _ -> :error
      end
    end

    serialize fn date ->
      Date.to_iso8601(date)
    end
  end

  scalar :email do
    parse fn input ->
      with(
        %Absinthe.Blueprint.Input.String{value: value} <- input,
        [username, domain] <- String.split(value, "@")
      ) do
        {:ok, {username, domain}}
      else
        _ -> :error
      end
    end

    serialize fn {username, domain} ->
      "#{username}@#{domain}"
    end
  end

  scalar :decimal do
    parse fn
      %{value: value}, _ -> Decimal.parse(value)
      _, _ -> :error
    end
    serialize &to_string/1
  end


  @desc "An error encountered trying to persist input"
  object :input_error do
    field :key, non_null(:string)
    field :message, non_null(:string)
  end
end
