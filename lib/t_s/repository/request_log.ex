defmodule TS.Repository.RequestLog do
  use Ecto.Schema
  @primary_key false

  import Ecto.Changeset
  import Ecto.Query

  alias TS.Repository.{MoneyPlacement, Ticket, Shift}
  alias Helper.ChangesetHelper
  alias TS.Repo

  schema "request_logs" do
    field(:request_id, :string, primary_key: true)
    field(:target_table, :string)
    field(:target_id, :integer)
    field(:date_time_in, :naive_datetime)
  end

  def changeset(obj, params \\ %{}) do
    obj
    |> cast(params, [
      :request_id,
      :target_table,
      :target_id
    ])
    |> validate_required([
      :request_id,
      :target_table,
      :target_id
    ])
    |> unique_constraint(:request_id)
  end

  def check(nil) do
    :ok
  end

  def check(request_id) do
    from(rl in __MODULE__, where: rl.request_id == ^request_id)
    |> Repo.all()
    |> case do
      [] ->
        :ok

      [any | _] ->
        Repo.one(
          from(t in {any.target_table, Ticket},
            where: t.id == ^any.target_id,
            select: t.json
          )
        )
    end
  end

  def save(nil, _table, _id) do
    :ok
  end

  def save(request_id, table, id) do
    changeset(%__MODULE__{}, %{
      request_id: request_id,
      target_table: table,
      target_id: id
    })
    |> Repo.insert()
  end
end
