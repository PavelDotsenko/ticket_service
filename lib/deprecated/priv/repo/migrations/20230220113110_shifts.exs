defmodule TS.Repo.Migrations.Shifts do
  use Ecto.Migration

  def change do
    for date_postfix <- Application.get_env(:ticket_service, :table_dates_range) do
      create table("shifts_#{date_postfix}") do
        add :cashbox_id, :integer, null: false
        add :number, :integer, null: false
        add :open_time, :naive_datetime, null: false
        add :close_time, :naive_datetime
        add :is_online, :boolean, default: true, null: false
        add :start_sums, :map, null: false
        add :end_sums, :map
        add :state, :string, null: false, default: "open"
        add :date_time, :naive_datetime, null: false, default: fragment("now()")
      end
    end
  end
end
