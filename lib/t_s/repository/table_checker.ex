defmodule TS.Repository.TableChecker do
  def check(table, schema_text) do
    Ecto.Adapters.SQL.query(
      TS.Repo,
      "CREATE TABLE IF NOT EXISTS #{table} (#{schema_text})"
    )
  end

  def new_table_dates(start_date, table_prefix) do
    date_now = Calendar.strftime(start_date, "20%y_%m")
    date_prev = Calendar.strftime(NaiveDateTime.new!(year_handler(start_date.year, start_date.month, start_date.day), month_handler(start_date.month, start_date.day), 15, 12, 12, 12), "20%y_%m")
    if Ecto.Adapters.SQL.table_exists?(TS.Repo, table_prefix <> date_prev) and Ecto.Adapters.SQL.table_exists?(TS.Repo, table_prefix <> date_now) do
      [date_now, date_prev]
    else
      if Ecto.Adapters.SQL.table_exists?(TS.Repo, table_prefix <> date_now) do
        [date_now]
      else
        []
      end
    end
  end

  def all_table_dates(start_date, table_prefix, schema_text, table_list \\ [], not_repeat \\ true)

  def all_table_dates(start_date, table_prefix, schema_text, table_list, true) do
    date_now = Calendar.strftime(start_date, "20%y_%m")
    check(table_prefix <> date_now, schema_text)
    all_table_dates(NaiveDateTime.new!(year_handler(start_date.year, start_date.month, 1), month_handler(start_date.month, 1), 15, 12, 12, 12), table_prefix, schema_text, [date_now | table_list], false)
  end

  def all_table_dates(start_date, table_prefix, _schema_text, table_list, false) do
    date_now = Calendar.strftime(start_date, "20%y_%m")
    if Ecto.Adapters.SQL.table_exists?(TS.Repo, table_prefix <> date_now) do
      all_table_dates(NaiveDateTime.new!(year_handler(start_date.year, start_date.month, 1), month_handler(start_date.month, 1), 15, 12, 12, 12), table_prefix, nil, [date_now | table_list], false)
    else
      table_list
    end
  end

  defp year_handler(prev_year, 1, day) when day < 14 do
    prev_year - 1
  end

  defp year_handler(prev_year, _, day) when day < 14 do
    prev_year
  end

  defp year_handler(next_year, 12, _day) do
    next_year + 1
  end

  defp year_handler(next_year, _, _day) do
    next_year
  end

  defp month_handler(1, day) when day < 14 do
    12
  end

  defp month_handler(prev_month, day) when day < 14 do
    prev_month - 1
  end

  defp month_handler(12, _day) do
    1
  end

  defp month_handler(next_month, _day) do
    next_month + 1
  end
end
