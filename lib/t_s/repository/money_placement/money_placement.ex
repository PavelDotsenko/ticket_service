defmodule TS.Repository.MoneyPlacement do
  use Ecto.Schema

  import Ecto.Changeset

  alias Helper.ChangesetHelper
  alias TS.Type.MoneyType

  schema "" do
    field(:shift_id, :integer)
    field(:kkm_id, :integer)
    field(:type, MoneyType)
    field(:is_online, :boolean, default: true)
    field(:total_sum, :integer)
    field(:message, :binary)
    field(:date_time, :naive_datetime)
    field(:date_time_in, :naive_datetime)
  end

  def changeset(obj, params \\ %{}) do
    obj
    |> cast(params, [
      :shift_id,
      :kkm_id,
      :type,
      :is_online,
      :total_sum,
      :message,
      :date_time
    ])
    |> validate_required([
      :shift_id,
      :kkm_id,
      :type,
      :total_sum,
      :message,
      :date_time
    ])
    |> foreign_key_constraint(:shift_id)
    |> validate_number(:total_sum, greater_than: 0)
    |> ChangesetHelper.enum_type_check(:type, MoneyType)
  end
end
