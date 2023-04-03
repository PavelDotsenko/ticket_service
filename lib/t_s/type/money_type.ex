defmodule TS.Type.MoneyType do
  use EctoEnum.Postgres,
    type: :money_type,
    enums: [:OPEN_SHIFT, :CLOSE_SHIFT, :MONEY_PLACEMENT_WITHDRAWAL, :MONEY_PLACEMENT_DEPOSIT]

  @type type ::
          :OPEN_SHIFT | :CLOSE_SHIFT | :MONEY_PLACEMENT_WITHDRAWAL | :MONEY_PLACEMENT_DEPOSIT
end
