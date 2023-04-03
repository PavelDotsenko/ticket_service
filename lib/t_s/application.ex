defmodule TS.Application do
  use Application

  def start(_type, _args) do
    children = [
      TS.Repo
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: TS.Supervisor)
  end
end
