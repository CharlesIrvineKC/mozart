defmodule Mozart.UserManagerTest do
  use ExUnit.Case

  alias Mozart.UserManager

  setup do
    UserManager.start_link(nil)
    %{user: "foo"}
  end

  test "get users assigned groups", %{user: user} do
    assert UserManager.get_assigned_groups(user) == [:admin]
  end
end
