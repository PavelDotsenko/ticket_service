defmodule TS.Repo.Migrations.Money do
  use Ecto.Migration

  alias TS.Type.MoneyType

  def change do
    MoneyType.create_type()

    for date_postfix <- Application.get_env(:ticket_service, :table_dates_range) do
      create table("money_#{date_postfix}") do
        add :shift_id, references(:"shifts_#{date_postfix}"), null: false
        add :kkm_id, :integer, null: false
        add :type, MoneyType.type(), null: false
        add :is_online, :boolean, default: true, null: false
        add :total_sum, :integer, null: false
        add :message, :bytea, null: false
        add :date_time, :naive_datetime, null: false
        add :date_time_in, :naive_datetime, null: false, default: fragment("now()")
      end
    end
  end
end
