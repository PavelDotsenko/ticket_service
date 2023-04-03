defmodule TS.Utl do
  @offset 6
  ##############################################################################
  # def now_date_time do
  #   {{xyear, xmonth, xday}, {xhour, xmiunute, xsecond}} = :calendar.local_time()

  #   %Ofd.Proto.DateTime{
  #     date: %Ofd.Proto.Date{day: xday, month: xmonth, year: xyear},
  #     time: %Ofd.Proto.Time{hour: xhour, minute: xmiunute, second: xsecond}
  #   }
  # end

  ##############################################################################
  @doc """
  # message Money {
  #   required uint64 bills = 1;
  #   required uint32 coins = 2;
  # }
  """
  def money(xbills, xcoins) do
    %{bills: xbills, coins: xcoins}
  end

  def int_to_money(val) do
    %{bills: trunc(val / 100), coins: rem(val, 100)}
  end

  def money_to_int(money) when is_struct(money) do
    money_to_int(Map.from_struct(money))
  end

  def money_to_int(money) do
    bills = money[:bills] || money["bills"]
    coins = money[:coins] || money["coins"]
    bills * 100 + coins
  end

  def get_next_reqnum(reqnum), do: reqnum + 1

  def prepare_no_camel(%Date{} = value) do
    Date.to_iso8601(value)
  end

  def prepare_no_camel(%Time{} = value) do
    Time.to_iso8601(value)
  end

  def prepare_no_camel(%DateTime{} = value) do
    DateTime.to_iso8601(value, :extended, 3600 * @offset)
  end

  def prepare_no_camel(%NaiveDateTime{} = value) do
    {:ok, value} = DateTime.from_naive(value, "Etc/UTC")
    DateTime.to_iso8601(value, :extended, 3600 * @offset)
  end

  def prepare_no_camel(struct) when is_struct(struct) do
    Map.from_struct(struct)
    |> Map.drop([:__meta__, :__struct__])
    |> prepare_no_camel()
  end

  def prepare_no_camel(map) when is_map(map) do
    Enum.map(map, fn
      {key, value} ->
        {key, prepare_no_camel(value)}
    end)
    |> Map.new()
  end

  def prepare_no_camel(list) when is_list(list) do
    Enum.map(list, fn value -> prepare_no_camel(value) end)
  end

  def prepare_no_camel({:error, val}) do
    prepare_no_camel(val)
  end

  def prepare_no_camel(tuple) when is_tuple(tuple) do
    IO.puts("WARNING, TUPLE FOUND: #{inspect(tuple)}")

    Tuple.to_list(tuple)
    |> prepare_no_camel()
  end

  def prepare_no_camel(value) when is_pid(value) do
    value
  end

  def prepare_no_camel(value) do
    value
  end

  def to_map(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct =
      Map.from_struct(ecto_struct)
      |> Map.drop([:__meta__])

    Enum.map(ecto_struct, fn
      {key, value} when not is_atom(key) ->
        {:"#{key}", to_map(value)}

      {key, value} ->
        {key, to_map(value)}
    end)
    |> Map.new()
  end

  def to_map(map) when is_map(map) do
    Enum.map(map, fn
      {key, value} when not is_atom(key) ->
        {:"#{key}", to_map(value)}

      {key, value} ->
        {key, to_map(value)}
    end)
    |> Map.new()
  end

  def to_map(val) do
    val
  end

  def ofd_date_time_to_normal(%NaiveDateTime{} = date_time) do
    date_time
  end

  def ofd_date_time_to_normal(%DateTime{} = date_time) do
    date_time
  end

  def ofd_date_time_to_normal(date_time) when is_struct(date_time) do
    %NaiveDateTime{year: date_time.date.year, month: date_time.date.month, day: date_time.date.day, hour: date_time.time.hour, minute: date_time.time.minute, second: date_time.time.second}
  end

  def ofd_date_time_to_normal(date_time) do
    date_time
  end

  def operation_type(type) do
    case to_string(type) do
      "OPERATION_SELL" -> "Продажа"
      "OPERATION_SELL_RETURN" -> "Возврат продажи"
      "OPERATION_BUY_RETURN" -> "Возврат покупки"
      "OPERATION_BUY" -> "Покупка"
      any -> any
    end
  end

  def payment_type(type) do
    case to_string(type) do
      "PAYMENT_MOBILE" -> "Мобильные"
      "PAYMENT_CARD" -> "Картой"
      "PAYMENT_CASH" -> "Наличные"
      any -> any
    end
  end

  def money_placement_type(type) do
    case to_string(type) do
      "MONEY_PLACEMENT_WITHDRAWAL" -> "Выплаты"
      "MONEY_PLACEMENT_DEPOSIT" -> "Внесения"
      any -> any
    end
  end
end
