defmodule TS.Repository.Shift do
  use Ecto.Schema

  import Ecto.Changeset
  import EctoEnum

  alias Helper.ChangesetHelper

  defenum(Status, open: "open", closed: "closed")

  schema "" do
    field(:cashbox_id, :integer)
    field(:number, :integer)
    field(:open_time, :naive_datetime)
    field(:close_time, :naive_datetime)
    field(:is_online, :boolean)
    field(:start_sums, :map)
    field(:end_sums, :map)
    field(:state, Status, default: :open)
    field(:date_time, :naive_datetime)
  end

  def changeset(obj, params \\ %{}) do
    obj
    |> cast(params, [
      :cashbox_id,
      :number,
      :open_time,
      :close_time,
      :is_online,
      :start_sums,
      :end_sums,
      :state,
      :date_time
    ])
    |> validate_required([:cashbox_id, :number, :start_sums])
    |> validate_number(:number, greater_than: 0)
    |> ChangesetHelper.enum_type_check(:state, Status)
  end
end
