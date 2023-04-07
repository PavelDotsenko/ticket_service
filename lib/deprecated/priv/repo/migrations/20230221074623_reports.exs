defmodule TS.Repo.Migrations.Reports do
  use Ecto.Migration

  alias TS.Type.ReportType

  def change do
    ReportType.create_type()

    for date_postfix <- Application.get_env(:ticket_service, :table_dates_range) do
      create table("reports_#{date_postfix}") do
        add :shift_id, references(:"shifts_#{date_postfix}"), null: false
        add :kkm_id, :integer, null: false
        add :type, ReportType.type(), null: false
        add :report, :map, null: false
        add :message, :bytea, null: false

        timestamps()
      end
    end
  end
end
