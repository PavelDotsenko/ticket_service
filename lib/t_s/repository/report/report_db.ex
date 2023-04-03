# defmodule ApiCore.DynamicRepository.Report do
#   use Ecto.Schema
#   alias TS.Repo
#   alias TS.Repository.Report
#   alias Ecto.Schema.Metadata
#   alias TS.Repository.Ticket.Db, as: Ticket
#   alias TS.Repository.Shift.Db, as: Shift
#   alias TS.Repository.MoneyPlacement.Db, as: MoneyPlacement
#   import Ecto.Query

#   defstruct [
#     :id,
#     :shift_id,
#     :kkm_id,
#     :type,
#     :report,
#     :message,
#     :inserted_at,
#     :updated_at
#   ]

#   defp create(
#          shift_id,
#          shift_date_time,
#          kkm_id,
#          state,
#          type,
#          date_time
#        ) do
#     date = Calendar.strftime(shift_date_time, "20%y_%m")

#     cond do
#       not Ecto.Adapters.SQL.table_exists?(Repo, "reports_#{date}") ->
#         {:error, "reports_#{date} doesn't exist"}

#       true ->
#         report = make_zx_report(shift_id, shift_date_time, state, date_time)
#         {:ok, json} = Jason.encode(Utl.prepare_no_camel(report))

#         Repo.query(
#           "INSERT INTO reports_#{date} (shift_id, kkm_id, type, report, message, inserted_at, updated_at) VALUES (#{shift_id}, #{kkm_id}, '#{type}', '#{json}', $1, '#{date_time}', '#{date_time}')",
#           [Ofd.Proto.ZXReport.encode(report)]
#         )
#         |> case do
#           {:ok, _} ->
#             {:ok, report}

#           any ->
#             any
#         end
#     end
#   end

#   defp update(
#          shift_id,
#          shift_date_time,
#          state,
#          type,
#          date_time
#        ) do
#     date = Calendar.strftime(shift_date_time, "20%y_%m")

#     cond do
#       not Ecto.Adapters.SQL.table_exists?(Repo, "reports_#{date}") ->
#         {:error, "reports_#{date} doesn't exist"}

#       true ->
#         report = make_zx_report(shift_id, shift_date_time, state, date_time)
#         {:ok, json} = Jason.encode(Utl.prepare_no_camel(report))

#         Repo.query(
#           "UPDATE reports_#{date} SET type='#{type}', report='#{json}', message=$1, updated_at='#{date_time}' WHERE shift_id=#{shift_id}",
#           [Ofd.Proto.ZXReport.encode(report)]
#         )
#         |> case do
#           {:ok, _} ->
#             {:ok, report}

#           any ->
#             any
#         end
#     end
#   end

#   def get_last_z_report_by_cashbox_id(kkm_id) do
#     dates_range = Application.get_env(:api_core, :table_dates_range)
#     local_now = NaiveDateTime.local_now()

#     dates_range =
#       Enum.reduce_while(dates_range, [], fn
#         date, dates_range ->
#           date_now = Calendar.strftime(local_now, "20%y_%m")

#           if date == date_now do
#             {:halt, dates_range ++ [date]}
#           else
#             {:cont, dates_range ++ [date]}
#           end
#       end)

#     select_query =
#       Enum.map(dates_range, fn date ->
#         "SELECT * FROM reports_#{date} WHERE kkm_id = #{kkm_id}"
#       end)
#       |> Enum.join(" UNION ")

#     {_, query} = Repo.query(select_query <> " ORDER BY inserted_at DESC LIMIT 1")

#     if query.rows == [] do
#       nil
#     else
#       Enum.zip(Enum.map(query.columns, fn column -> :"#{column}" end), Enum.at(query.rows, 0))
#       |> Map.new()
#     end
#   end

#   def get_report_for_shift_id_and_open_date(
#         shift_id,
#         shift_date_time,
#         kkm_id,
#         state,
#         is_close_shift,
#         date_time
#       ) do
#     date = Calendar.strftime(shift_date_time, "20%y_%m")
#     type = if is_close_shift or not state.live_data.shift.is_open, do: :Z_REPORT, else: :X_REPORT
#     {_, query} = Repo.query("SELECT * FROM reports_#{date} WHERE shift_id = #{shift_id}")

#     if query.rows == [] do
#       nil
#     else
#       Enum.zip(Enum.map(query.columns, fn column -> :"#{column}" end), Enum.at(query.rows, 0))
#       |> Map.new()
#     end
#     |> case do
#       nil ->
#         create(shift_id, shift_date_time, kkm_id, state, type, date_time)

#       _ ->
#         update(shift_id, shift_date_time, state, type, date_time)
#     end
#   end

#   # ApiCore.Repository.Report.make_zx_report(8, date, %{amount_of_money: 1000}, date)
#   # {:ok, date} = NaiveDateTime.new(2022, 8, 12, 12, 12, 12)
#   def make_zx_report(shift_id, shift_date_time, state, date_time) do
#     shift = Shift.get_shift_by_id_and_date(shift_id, shift_date_time)

#     tickets =
#       Ticket.get_tickets_for_shift_id_and_open_date(shift_id, shift_date_time) ||
#         []

#     ticket_messages = Enum.map(tickets, &Ofd.Proto.TicketRequest.decode(&1.message))
#     operations = create_operations(tickets)

#     money_placements =
#       MoneyPlacement.get_money_placements_for_shift_id_and_open_date(
#         shift_id,
#         shift_date_time
#       ) || []

#     revenue =
#       Enum.reduce(
#         tickets,
#         0,
#         &if(&1.type == "OPERATION_SELL" or &1.type == "OPERATION_BUY_RETURN",
#           do: &1.total_sum + &2,
#           else: &2 - &1.total_sum
#         )
#       )

#     {start_non_nulls, non_nulls} = create_non_nulls(shift, state)

#     %Ofd.Proto.ZXReport{
#       annulled_tickets: nil,
#       cash_sum: %Ofd.Proto.Money{bills: 0, coins: 0},
#       checksum: nil,
#       close_shift_time:
#         if shift.close_time do
#           %Ofd.Proto.DateTime{
#             date: %Ofd.Proto.Date{
#               day: shift.close_time.day,
#               month: shift.close_time.month,
#               year: shift.close_time.year
#             },
#             time: %Ofd.Proto.Time{
#               hour: shift.close_time.hour,
#               minute: shift.close_time.minute,
#               second: shift.close_time.second
#             }
#           }
#         else
#           nil
#         end,
#       date_time: %Ofd.Proto.DateTime{
#         date: %Ofd.Proto.Date{day: date_time.day, month: date_time.month, year: date_time.year},
#         time: %Ofd.Proto.Time{
#           hour: date_time.hour,
#           minute: date_time.minute,
#           second: date_time.second
#         }
#       },
#       discounts: [],
#       markups: [],
#       money_placements: create_money_placements(money_placements, shift.cashbox_id),
#       non_nullable_sums: non_nulls,
#       open_shift_time: %Ofd.Proto.DateTime{
#         date: %Ofd.Proto.Date{
#           day: shift.open_time.day,
#           month: shift.open_time.month,
#           year: shift.open_time.year
#         },
#         time: %Ofd.Proto.Time{
#           hour: shift.open_time.hour,
#           minute: shift.open_time.minute,
#           second: shift.open_time.second
#         }
#       },
#       operations: operations,
#       revenue: %Ofd.Proto.ZXReport.Revenue{
#         is_negative: if(revenue < 0, do: true, else: false),
#         sum: Utl.int_to_money(if(revenue < 0, do: -revenue, else: revenue))
#       },
#       sections: [
#         %Ofd.Proto.ZXReport.Section{
#           operations: operations,
#           section_code: "1"
#         }
#       ],
#       shift_number: shift.number,
#       start_shift_non_nullable_sums: start_non_nulls,
#       taxes: create_taxes(ticket_messages),
#       ticket_operations: create_ticket_operations(tickets, ticket_messages, shift.cashbox_id),
#       total_result: operations
#     }
#   end

#   defp create_non_nulls(shift, state) do
#     start_sums = shift.start_sum
#     end_sums = shift.end_sum || state.live_data.shift.non_nullable_sums

#     {
#       Enum.reduce(start_sums, [], fn
#         {_key, 0}, acc ->
#           acc

#         {key, _}, acc ->
#           [
#             %Ofd.Proto.ZXReport.NonNullableSum{
#               operation: :"OPERATION_#{String.upcase(to_string(key), :ascii)}",
#               sum: Utl.int_to_money(Map.get(start_sums, key))
#             }
#           ] ++ acc
#       end),
#       Enum.reduce(end_sums, [], fn
#         {_key, 0}, acc ->
#           acc

#         {key, _}, acc ->
#           [
#             %Ofd.Proto.ZXReport.NonNullableSum{
#               operation: :"OPERATION_#{String.upcase(to_string(key), :ascii)}",
#               sum: Utl.int_to_money(Map.get(end_sums, key))
#             }
#           ] ++ acc
#       end)
#     }
#   end

#   defp create_operations(tickets) do
#     operation_sell = Enum.filter(tickets, &(&1.type == "OPERATION_SELL"))
#     operation_sell_return = Enum.filter(tickets, &(&1.type == "OPERATION_SELL_RETURN"))
#     operation_buy = Enum.filter(tickets, &(&1.type == "OPERATION_BUY"))
#     operation_buy_return = Enum.filter(tickets, &(&1.type == "OPERATION_BUY_RETURN"))

#     Enum.reduce(
#       [operation_buy, operation_buy_return, operation_sell, operation_sell_return],
#       [],
#       fn operations, acc ->
#         if operations != [] do
#           acc ++
#             [
#               %Ofd.Proto.ZXReport.Operation{
#                 count: length(operations),
#                 operation: :"#{hd(operations).type}",
#                 sum: Utl.int_to_money(Enum.reduce(operations, 0, &(&2 + &1.total_sum)))
#               }
#             ]
#         else
#           acc
#         end
#       end
#     )
#   end

#   def create_money_placements(money_placements, kkm_id) do
#     {w_count, d_count} =
#       MoneyPlacement.get_money_placement_count_for_kkm_id(kkm_id)

#     if money_placements do
#       withdraw = Enum.filter(money_placements, &(&1.type == "MONEY_PLACEMENT_WITHDRAWAL"))
#       deposit = Enum.filter(money_placements, &(&1.type == "MONEY_PLACEMENT_DEPOSIT"))

#       [
#         %Ofd.Proto.ZXReport.MoneyPlacement{
#           offline_count: length(Enum.filter(withdraw, &(&1.is_online == false))),
#           operation: :MONEY_PLACEMENT_WITHDRAWAL,
#           operations_count: length(withdraw),
#           operations_sum: Utl.int_to_money(Enum.reduce(withdraw, 0, &(&2 + &1.total_sum))),
#           operations_total_count: w_count || 0
#         },
#         %Ofd.Proto.ZXReport.MoneyPlacement{
#           offline_count: length(Enum.filter(deposit, &(&1.is_online == false))),
#           operation: :MONEY_PLACEMENT_DEPOSIT,
#           operations_count: length(deposit),
#           operations_sum: Utl.int_to_money(Enum.reduce(deposit, 0, &(&2 + &1.total_sum))),
#           operations_total_count: d_count || 0
#         }
#       ]
#     else
#       [
#         %Ofd.Proto.ZXReport.MoneyPlacement{
#           offline_count: 0,
#           operation: :MONEY_PLACEMENT_WITHDRAWAL,
#           operations_count: 0,
#           operations_sum: %Ofd.Proto.Money{bills: 0, coins: 0},
#           operations_total_count: w_count
#         },
#         %Ofd.Proto.ZXReport.MoneyPlacement{
#           offline_count: 0,
#           operation: :MONEY_PLACEMENT_DEPOSIT,
#           operations_count: 0,
#           operations_sum: %Ofd.Proto.Money{bills: 0, coins: 0},
#           operations_total_count: d_count
#         }
#       ]
#     end
#   end

#   defp create_ticket_operations(tickets, ticket_messages, kkm_id) do
#     Enum.map(tickets, &if(is_atom(&1.type), do: &1.type, else: :"#{&1.type}"))
#     |> Enum.uniq()
#     |> Enum.reduce([], fn operation, acc ->
#       ticket_messages = Enum.filter(ticket_messages, &(&1.operation == operation))
#       tickets = Enum.filter(tickets, &(&1.type == to_string(operation)))

#       {change, discount, markup} =
#         Enum.reduce(ticket_messages, {0, 0, 0}, fn ticket, {change, discount, markup} ->
#           {
#             change + if(ticket.amounts.change, do: Utl.money_to_int(ticket.amounts.change), else: 0),
#             discount + if(ticket.amounts.discount, do: Utl.money_to_int(ticket.amounts.discount), else: 0),
#             markup + if(ticket.amounts.markup, do: Utl.money_to_int(ticket.amounts.markup), else: 0)
#           }
#         end)

#         [
#           %Ofd.Proto.ZXReport.TicketOperation{
#             change_sum: Utl.int_to_money(change),
#             discount_sum: Utl.int_to_money(discount),
#             markup_sum: Utl.int_to_money(markup),
#             offline_count: length(Enum.filter(tickets, &(&1.is_online == false))),
#             operation: operation,
#             payments: create_payments(ticket_messages),
#             tickets_count: length(tickets),
#             tickets_sum: Utl.int_to_money(Enum.reduce(tickets, 0, &(&2 + &1.total_sum))),
#             tickets_total_count:
#               Ticket.get_tickets_count_for_kkm_id_and_type(
#                 kkm_id,
#                 to_string(operation)
#               )
#           }
#          | acc]
#     end)
#   end

#   defp create_payments(ticket_messages) do
#     payments =
#       Enum.map(ticket_messages, & &1.payments)
#       |> List.flatten()

#     cash = Enum.filter(payments, &(&1.type == :PAYMENT_CASH))
#     card = Enum.filter(payments, &(&1.type == :PAYMENT_CARD))

#     Enum.reduce([cash, card], [], fn payment, acc ->
#       if payment != [] do
#         [
#           %Ofd.Proto.ZXReport.TicketOperation.Payment{
#             count: length(payment),
#             payment: :"#{hd(payment).type}",
#             sum: Utl.int_to_money(Enum.reduce(payment, 0, &(&2 + Utl.money_to_int(&1.sum))))
#           }
#         | acc]
#       else
#         acc
#       end
#     end)
#   end

#   def create_taxes(ticket_messages) do
#     taxes =
#       Enum.map(ticket_messages, & &1.items)
#       |> List.flatten()
#       |> Enum.map(& &1.commodity || &1.storno_commodity)
#       |> List.flatten()
#       |> Enum.map(& &1.taxes)
#       |> List.flatten()

#     Enum.reduce(taxes, [], fn tax, acc ->
#       if tax.type not in Enum.map(acc, & &1.type) or
#            tax.percent not in Enum.map(acc, & &1.percent) do
#         [
#           %Ofd.Proto.ZXReport.Tax{
#             operations: create_tax_operations(ticket_messages, tax.percent, tax.type),
#             percent: tax.percent,
#             type: tax.type
#           }
#         | acc]
#       else
#         acc
#       end
#     end)
#   end

#   def create_tax_operations(tickets, percent, type) do
#     sell = Enum.filter(tickets, &(&1.operation == :OPERATION_SELL))
#     return = Enum.filter(tickets, &(&1.operation == :OPERATION_SELL_RETURN))

#     Enum.reduce([sell, return], [], fn tickets, acc ->
#       items =
#         Enum.map(tickets, & &1.items)
#         |> List.flatten()

#       commodities =
#         Enum.map(items, & &1.commodity || &1.storno_commodity)
#         |> List.flatten()

#       taxes =
#         Enum.map(commodities, & &1.taxes)
#         |> List.flatten()
#         |> Enum.filter(&(&1.percent == percent and &1.type == type))

#       if tickets != [] and taxes != [] do
#         commodities = Enum.filter(commodities, &(Enum.at(&1.taxes, 0) in taxes))
#         turnover = Enum.reduce(commodities, 0, &(Utl.money_to_int(&1.sum) + &2))
#         tax_sum = Enum.reduce(taxes, 0, &(&2 + Utl.money_to_int(&1.sum)))

#         [
#           %Ofd.Proto.ZXReport.Tax.TaxOperation{
#             operation: Enum.at(tickets, 0).operation,
#             sum: Utl.int_to_money(tax_sum),
#             turnover: Utl.int_to_money(turnover),
#             turnover_without_tax: Utl.int_to_money(turnover - tax_sum)
#           }
#         | acc]
#       else
#         acc
#       end
#     end)
#   end
# end
