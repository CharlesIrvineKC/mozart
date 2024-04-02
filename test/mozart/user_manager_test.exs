defmodule Mozart.UserManagerTest do
  use ExUnit.Case

  alias Mozart.UserManager
  alias Mozart.Data.User

  setup do
    UserManager.start_link(nil)
    %{user: %User{name: "Irvine", groups: [:admin]}}
  end

  test "add a user", %{user: user} do
    UserManager.insert_user(user)
  end

  test "get a user", %{user: user} do
    UserManager.insert_user(user)
    assert UserManager.get_user(user.name).name == user.name
  end
end
