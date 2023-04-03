defmodule TS.Repo.Migrations.Tickets do
  use Ecto.Migration

  alias TS.Type.TicketType

  def change do
    TicketType.create_type()

    for date_postfix <- Application.get_env(:ticket_service, :table_dates_range) do
      create table("tickets_#{date_postfix}") do
        add :shift_id, references(:"shifts_#{date_postfix}"), null: false
        add :kkm_id, :integer, null: false
        add :type, TicketType.type(), null: false
        add :number, :integer
        add :fiscal_mark, :string, null: false
        add :total_sum, :integer, null: false
        add :json, :map, null: false
        add :message, :bytea, null: false
        add :is_online, :boolean, default: true, null: false
        add :date_time, :naive_datetime, null: false
        add :date_time_in, :naive_datetime, null: false, default: fragment("now()")
      end
    end
  end
end
