defmodule Mozart.Data.Task do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :sub_process,
    inputs: [],
    choices: [],
    assigned_groups: [],
    complete: false,
    data: %{}
  ]

  def complete_able(t) when t.type == :service do
    true
  end

  def complete_able(t) when t.type == :choice do
    true
  end

  def complete_able(t) when t.type == :sub_process do
    t.complete
  end

  def complete_able(t) when t.type == :join do
    t.inputs == []
  end

  def complete_able(t) when t.type == :user do
    t.complete
  end
end
