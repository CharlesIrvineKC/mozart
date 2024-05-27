defmodule Mozart.Parser.ParserUtil do
  @moduledoc false
  import NimbleParsec

  def spaces do
    ascii_string([?\s], min: 1)
  end

  def identifier do
    ascii_string([?a..?z, ?A..?Z, ?_], min: 1)
  end
end
