defmodule Mozart.Data.Task do
  defstruct [
    :name,
    :type,
    :function,
    :next,
    :uid,
    :process_uid,
    :sub_process,
    :assignee,
    :timer_duration,
    expired: false,
    event_received: false,
    multi_next: [],
    inputs: [],
    choices: [],
    assigned_groups: [],
    complete: false,
    data: %{}
  ]

  def complete_able(t) when t.type == :service do
    true
  end

  def complete_able(t) when t.type == :send_event do
    true
  end

  def complete_able(t) when t.type == :receive_event do
    t.event_received
  end

  def complete_able(t) when t.type == :timer do
    t.expired
  end

  def complete_able(t) when t.type == :parallel do
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
