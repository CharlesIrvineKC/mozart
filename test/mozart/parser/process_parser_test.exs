defmodule Mozart.Parser.ProcessParserTest do
  use ExUnit.Case

  alias Mozart.Parser.ServiceTaskParser, as: SP
  alias Mozart.Parser.UserTaskParser, as: UP

  test "parse service task" do
    service_task = "service_task add_one do value = value + 1 end"
    {:ok, output, _, _, _, _} = SP.service_parser(service_task)
    [service_name, parameter, _, _, _] = output
    assert service_name == "add_one"
    assert parameter == "value"
  end

  test "parse user task" do
    user_task = "user_task provide_loan_amount assigned_groups [\"under writing\"]"
    {:ok, output, _, _, _, _} = UP.user_task_parser(user_task)
    IO.inspect(output)
  end
end
