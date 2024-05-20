defmodule Mozart.Parser.ServiceParser do
  import NimbleParsec

  service_name = ascii_string([?a..?z, ?A..?Z, ?_], min: 1)
  property_name = ascii_string([?a..?z, ?A..?Z, ?_], min: 1)
  spaces = ascii_string([?\s], min: 1)

  term =
    ascii_string([?a..?z, ?A..?Z, ?_, ?0..?9], min: 1)

  operator =
    string("+")

  expression =
    term
    |> ignore(spaces)
    |> concat(operator)
    |> ignore(spaces)
    |> concat(term)

  service =
    ignore(string("call_service "))
    |> concat(service_name)
    |> ignore(spaces)
    |> ignore(string("do"))
    |> ignore(spaces)
    |> concat(property_name)
    |> ignore(spaces)
    |> ignore(string("="))
    |> ignore(spaces)
    |> concat(expression)
    |> ignore(spaces)
    |> ignore(string("end"))

  defparsec(:service_parser, service)

end
