defmodule TS.Repository.MoneyPlacement.Db do
  use Ecto.Schema
  alias TS.Repo
  alias TS.Repository.{MoneyPlacement, TableChecker}
  alias Ecto.Schema.Metadata
  import Ecto.Query

  def create(
        shift_id,
        shift_date_time,
        kkm_id,
        date_time,
        is_online,
        money_request,
        encoded
      ) do
    date = Calendar.strftime(shift_date_time, "20%y_%m")

    TableChecker.check("money_#{date}", schema_text())

        Map.put(%MoneyPlacement{}, :__meta__, %Metadata{
          state: :loaded,
          source: "money_#{date}",
          context: nil
        })
        |> MoneyPlacement.changeset(%{
          shift_id: shift_id,
          kkm_id: kkm_id,
          type: to_string(money_request.operation),
          total_sum: TS.Utl.money_to_int(money_request.sum),
          message: encoded,
          is_online: is_online,
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

  def get_money_placements_for_shift_id_and_open_date(shift_id, date_time) do
    date = Calendar.strftime(date_time, "20%y_%m")

    Repo.all(
      from(m in {"money_#{date}", Shift},
        where: m.shift_id == ^shift_id,
        order_by: [desc: m.date_time]
      )
    )
    |> case do
      [] -> nil
      any -> any
    end
  end

  def get_money_placement_count_for_kkm_id(kkm_id) do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "money_")

    {withq, depq} =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          {from(m in {"money_#{date}", Shift},
             where: m.kkm_id == ^kkm_id and m.type == "MONEY_PLACEMENT_WITHDRAWAL"
           ),
           from(m in {"money_#{date}", Shift},
             where: m.kkm_id == ^kkm_id and m.type == "MONEY_PLACEMENT_DEPOSIT"
           )}

        date, acc ->
          {from(m in {"money_#{date}", Shift},
             where: m.kkm_id == ^kkm_id and m.type == "MONEY_PLACEMENT_WITHDRAWAL",
             union_all: ^acc
           ),
           from(m in {"money_#{date}", Shift},
             where: m.kkm_id == ^kkm_id and m.type == "MONEY_PLACEMENT_DEPOSIT",
             union_all: ^acc
           )}
      end)

    withdraw =
      withq
      |> Repo.all()
      |> case do
        [] -> nil
        any -> Enum.count(any)
      end

    deposit =
      depq
      |> Repo.all()
      |> case do
        [] -> nil
        any -> Enum.count(any)
      end

    {withdraw, deposit}
  end

  defp schema_text() do
    "id serial PRIMARY KEY, shift_id INT NOT NULL, kkm_id INT NOT NULL, type VARCHAR(50) NOT NULL, is_online BOOLEAN NOT NULL DEFAULT true, total_sum INT NOT NULL, message BYTEA NOT NULL, date_time TIMESTAMP NOT NULL DEFAULT NOW(), date_time_in TIMESTAMP NOT NULL DEFAULT NOW()"
  end
end
