defmodule TS.Repository.Shift.Db do
  use Ecto.Schema
  alias TS.Repo
  alias TS.Repository.{Shift, TableChecker}
  alias Ecto.Schema.Metadata
  import Ecto.Query

  @schema_text "id serial PRIMARY KEY, cashbox_id INT NOT NULL, number INT NOT NULL, open_time TIMESTAMP NOT NULL DEFAULT NOW(), close_time TIMESTAMP, is_online BOOLEAN NOT NULL DEFAULT true, start_sums JSONB NOT NULL, end_sums JSONB, state VARCHAR(255) NOT NULL, date_time TIMESTAMP NOT NULL DEFAULT NOW()"

  def create(cashbox_id, shift_number, open_time, is_online, start_sum, date_time) do
    date_now = open_time |> Calendar.strftime("20%y_%m")

    TableChecker.check("shifts_#{date_now}", @schema_text)

    Map.put(%Shift{}, :__meta__, %Metadata{
      state: :loaded,
      source: "shifts_#{date_now}",
      context: nil
    })
    |> Shift.changeset(%{
      state: "open",
      cashbox_id: cashbox_id,
      number: shift_number,
      is_online: is_online,
      start_sums: start_sum,
      open_time: open_time,
      date_time: date_time
    })
    |> Repo.insert()
    |> case do
      {:ok, _} ->
        :ok

      any ->
        any
    end
  end

  def close(
        cashbox_id,
        close_time,
        end_sums
      ) do
    last_shift = get_last_shift_for_cashbox(cashbox_id)

    Shift.changeset(last_shift, %{
      state: "closed",
      close_time: close_time,
      end_sums: end_sums
    })
    |> Repo.update()
    |> case do
      {:ok, _} ->
        :ok

      any ->
        any
    end
  end

  def get_last_shift_for_cashbox(cashbox_id) do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "shifts_", @schema_text)

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          c_date= Calendar.strftime(date, "20%y_%m")
          TableChecker.check("shifts_#{c_date}", @schema_text)

          from(s in {"shifts_#{date}", Shift}, where: s.cashbox_id == ^cashbox_id)

        date, acc ->
          c_date= Calendar.strftime(date, "20%y_%m")
          TableChecker.check("shifts_#{c_date}", @schema_text)

          from(s in {"shifts_#{date}", Shift}, where: s.cashbox_id == ^cashbox_id, union_all: ^acc)
      end)

    select_query
    |> order_by(desc: fragment("open_time"))
    |> limit(1)
    |> Repo.one()
    |> case do
      nil ->
        nil

      shift ->
        Map.put(shift, :__meta__, %Metadata{
          state: :loaded,
          source: "shifts_#{shift.open_time |> Calendar.strftime("20%y_%m")}",
          context: nil
        })
    end
  end

  def get_shift_by_id_and_date(shift_id, date_time) do
    date = Calendar.strftime(date_time, "20%y_%m")
    TableChecker.check("shifts_#{date}", @schema_text)

    Repo.one(from(s in {"shifts_#{date}", Shift}, where: s.id == ^shift_id))
  end

  def get_all_shift_for_cashbox_id(cashbox_id, start_date, end_date) do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "shifts_", @schema_text, [], 99)

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          c_date= Calendar.strftime(date, "20%y_%m")
          TableChecker.check("shifts_#{c_date}", @schema_text)

          from(s in {"shifts_#{date}", Shift},
            where:
              s.cashbox_id == ^cashbox_id and fragment("open_time > ?", ^start_date) and
                fragment("open_time < ?", ^end_date)
          )

        date, acc ->
          c_date= Calendar.strftime(date, "20%y_%m")
          TableChecker.check("shifts_#{c_date}", @schema_text)

          from(s in {"shifts_#{date}", Shift},
            where:
              s.cashbox_id == ^cashbox_id and fragment("open_time > ?", ^start_date) and
                fragment("open_time < ?", ^end_date),
            union_all: ^acc
          )
      end)

    select_query
    |> order_by(desc: fragment("open_time"))
    |> Repo.all()
  end
end
