defmodule Mozart.Parser.UserTaskParser do
  import NimbleParsec
  import Mozart.Parser.ParserUtil

  # user_task provide_loan_amount assigned_groups ["under writing"]

  user_task =
    ignore(string("user_task"))
    |> ignore(spaces())

  defparsec(:user_task_parser, user_task)

end
