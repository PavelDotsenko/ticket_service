defmodule TS.Type.TicketType do
  use EctoEnum.Postgres,
    type: :ticket_type,
    enums: [:OPERATION_SELL, :OPERATION_SELL_RETURN, :OPERATION_BUY, :OPERATION_BUY_RETURN]

  @type type :: :OPERATION_SELL | :OPERATION_SELL_RETURN | :OPERATION_BUY | :OPERATION_BUY_RETURN
end
