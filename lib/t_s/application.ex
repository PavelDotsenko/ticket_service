defmodule TS.Application do
  use Application

  def start(_type, _args) do
    children = [
      TS.Repo
    ]

    out = Supervisor.start_link(children, strategy: :one_for_one, name: TS.Supervisor)
    TS.Repository.TableChecker.check("request_logs", "request_id VARCHAR(50) PRIMARY KEY, target_table VARCHAR(20) NOT NULL, target_id INT NOT NULL, date_time_in TIMESTAMP NOT NULL DEFAULT NOW()")
    out
  end
end
