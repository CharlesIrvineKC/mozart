defmodule Mozart.Parser.ServiceTaskParser do
  import NimbleParsec
  import Mozart.Parser.ParserUtil

  property_name =identifier() |> ignore(spaces())
  service_name = identifier() |> ignore(spaces())
  ignore_task_type = ignore(string("service_task")) |> ignore(spaces())

  term =
    ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1)

  operator =
    string("+")

  expression =
    term
    |> ignore(spaces())
    |> concat(operator)
    |> ignore(spaces())
    |> concat(term)

  service =
    ignore_task_type
    |> concat(service_name)
    |> ignore(string("do"))
    |> ignore(spaces())
    |> concat(property_name)
    |> ignore(string("="))
    |> ignore(spaces())
    |> concat(expression)
    |> ignore(spaces())
    |> ignore(string("end"))

  defparsec(:service_parser, service)

end
