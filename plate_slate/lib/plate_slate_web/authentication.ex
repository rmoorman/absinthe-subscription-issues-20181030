defmodule PlateSlateWeb.Authentication do

  @user_salt "user salt"
  @max_age 60 * 60 * 24 * 365

  def sign(data) do
    Phoenix.Token.sign(PlateSlateWeb.Endpoint, @user_salt, data)
  end

  def verify(token) do
    Phoenix.Token.verify(PlateSlateWeb.Endpoint, @user_salt, token, [
      max_age: @max_age
    ])
  end

end
