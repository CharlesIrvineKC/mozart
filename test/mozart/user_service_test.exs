defmodule Mozart.UserServiceTest do
  use ExUnit.Case

  alias Mozart.UserService
  alias Mozart.Data.User

  setup do
    {:ok, _pid} = UserService.start_link(nil)
    %{user: %User{name: "Irvine", groups: [:admin]}}
  end

  test "add a user", %{user: user} do
    UserService.insert_user(user)
  end

  test "get a user", %{user: user} do
    UserService.insert_user(user)
    assert UserService.get_user(user.name).name == user.name
  end
end
