defmodule TS.Repository.Ticket.Db do
  use Ecto.Schema
  alias TS.Repo
  alias TS.Repository.{Ticket, TableChecker}
  alias Ecto.Schema.Metadata
  import Ecto.Query

  @schema_text "id serial PRIMARY KEY, shift_id INT NOT NULL, kkm_id INT NOT NULL, type VARCHAR(50) NOT NULL, number INT NOT NULL, fiscal_mark VARCHAR(255) NOT NULL, total_sum BIGINT NOT NULL, json JSONB NOT NULL, message BYTEA NOT NULL, is_online BOOLEAN NOT NULL DEFAULT true, date_time TIMESTAMP NOT NULL DEFAULT NOW(), date_time_in TIMESTAMP NOT NULL DEFAULT NOW()"

  def create(
        shift_id,
        shift_date_time,
        kkm_id,
        date_time,
        number,
        fiscal_mark,
        is_online,
        total,
        operation,
        ticket,
        encoded,
        request_id \\ nil
      ) do
    date = Calendar.strftime(shift_date_time, "20%y_%m")

    TableChecker.check("tickets_#{date}", @schema_text)

    Map.put(%Ticket{}, :__meta__, %Metadata{
      state: :loaded,
      source: "tickets_#{date}",
      context: nil
    })
    |> Ticket.changeset(%{
      shift_id: shift_id,
      kkm_id: kkm_id,
      type: to_string(operation),
      number: number,
      fiscal_mark: fiscal_mark,
      total_sum: total,
      json: ticket,
      message: encoded,
      is_online: is_online,
      date_time: date_time
    })
    |> Repo.insert()
    |> case do
      {:ok, ticket} ->
        TS.Repository.RequestLog.save(request_id, "tickets_#{date}", ticket.id)
        :ok

      any ->
        any
    end
  end

  def get_tickets_for_shift_id_and_open_date(shift_id, date_time) do
    date = Calendar.strftime(date_time, "20%y_%m")

    TableChecker.check("tickets_#{date}", @schema_text)

    Repo.all(
      from(t in {"tickets_#{date}", Ticket},
        where: t.shift_id == ^shift_id,
        order_by: [desc: t.number]
      )
    )
  end

  def get_tickets_for_open_date(date_time) do
    date = Calendar.strftime(date_time, "20%y_%m")

    TableChecker.check("tickets_#{date}", @schema_text)
    
    from(t in {"tickets_#{date}", Ticket}, order_by: [desc: t.date_time])
    |> Repo.all()
  end

  def get_tickets_by_tables() do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "tickets_", @schema_text)

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          from(t in {"tickets_#{date}", Ticket}, order_by: [desc: t.date_time])

        date, acc ->
          from(t in {"tickets_#{date}", Ticket},
            union_all: ^acc
          )
      end)

    select_query
    |> Repo.all()
  end

  def get_ticket_by_ticket_id_and_open_date(ticket_id, date_time) do
    date = Calendar.strftime(date_time, "20%y_%m")

    TableChecker.check("tickets_#{date}", @schema_text)

    Repo.all(from(t in {"tickets_#{date}", Ticket}, where: t.id == ^ticket_id))
    |> case do
      [] -> nil
      [any | _] -> any
    end
  end

  def get_ticket_by_fiscal_mark_and_ticket_date_and_kkm_id(fiscal_mark, date, kkm_id) do
    get_ticket_by_fiscal_mark_and_ticket_date_and_kkm_id!(fiscal_mark, date, kkm_id)
    |> case do
      nil -> {:error, "ticket not found"}
      any -> {:ok, any}
    end
  end

  def get_ticket_by_fiscal_mark_and_ticket_date_and_kkm_id!(fiscal_mark, date_in, kkm_id) do
    dates_range = TableChecker.new_table_dates(date_in, "tickets_")

    if(dates_range == [], do: throw({:error, "date outside range of database tables"}))

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          from(t in {"tickets_#{date}", Ticket},
            where:
              t.fiscal_mark == ^fiscal_mark and t.kkm_id == ^kkm_id and
                fragment("cast(date_time as DATE) = ?", ^date_in)
          )

        date, acc ->
          from(t in {"tickets_#{date}", Ticket},
            where:
              t.fiscal_mark == ^fiscal_mark and t.kkm_id == ^kkm_id and
                fragment("cast(date_time as DATE) = ?", ^date_in),
            union_all: ^acc
          )
      end)

    select_query
    |> limit(1)
    |> Repo.one()
  end

  def get_tickets_for_kkm_id(kkm_id, start_date, end_date) do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "tickets_", @schema_text)

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          from(t in {"tickets_#{date}", Ticket},
            where:
              t.kkm_id == ^kkm_id and fragment("date_time > ?", ^start_date) and
                fragment("date_time < ?", ^end_date), order_by: [desc: t.date_time]
          )

        date, acc ->
          from(t in {"tickets_#{date}", Ticket},
            where:
              t.kkm_id == ^kkm_id and fragment("date_time > ?", ^start_date) and
                fragment("date_time < ?", ^end_date),
            union_all: ^acc
          )
      end)

    select_query
    |> Repo.all()
  end

  def get_tickets_count_for_kkm_id_and_type(kkm_id, type) do
    local_now = NaiveDateTime.local_now()

    dates_range = TableChecker.all_table_dates(local_now, "tickets_", @schema_text)

    select_query =
      Enum.reduce(dates_range, nil, fn
        date, nil ->
          from(t in {"tickets_#{date}", Ticket},
            where: t.kkm_id == ^kkm_id and t.type == ^to_string(type)
          )

        date, acc ->
          from(t in {"tickets_#{date}", Ticket},
            where: t.kkm_id == ^kkm_id and t.type == ^to_string(type),
            union_all: ^acc
          )
      end)

    select_query
    |> Repo.all()
    |> Enum.count()
  end
end
