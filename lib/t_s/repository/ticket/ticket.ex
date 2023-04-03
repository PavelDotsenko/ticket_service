defmodule TS.Repository.Ticket do
  use Ecto.Schema

  import Ecto.Changeset

  alias Helper.ChangesetHelper


  schema "" do
    field(:shift_id, :integer)
    field(:kkm_id, :integer)
    field(:type, :string)
    field(:number, :integer)
    field(:fiscal_mark, :string)
    field(:total_sum, :integer)
    field(:json, :map)
    field(:message, :binary)
    field(:is_online, :boolean)
    field(:date_time, :naive_datetime)
    field(:date_time_in, :naive_datetime)
  end

  def changeset(obj, params \\ %{}) do
    obj
    |> cast(params, [
      :shift_id,
      :kkm_id,
      :type,
      :number,
      :fiscal_mark,
      :total_sum,
      :json,
      :message,
      :is_online,
      :date_time,
      :date_time_in
    ])
    |> validate_required([
      :shift_id,
      :kkm_id,
      :type,
      :number,
      :fiscal_mark,
      :total_sum,
      :json,
      :message,
      :is_online,
      :date_time
    ])
    |> foreign_key_constraint(:shift_id)
    |> ChangesetHelper.normalize_string([:fiscal_mark, :type])
    |> ChangesetHelper.security_check([:fiscal_mark, :type])
  end
end
