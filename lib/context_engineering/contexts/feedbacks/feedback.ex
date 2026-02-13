defmodule ContextEngineering.Contexts.Feedbacks.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :query_id,
             :query_text,
             :overall_rating,
             :items_helpful,
             :items_not_helpful,
             :items_used,
             :missing_context,
             :agent_id,
             :session_id,
             :metadata,
             :inserted_at,
             :updated_at
           ]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "feedbacks" do
    field(:query_id, :binary_id)
    field(:query_text, :string)
    field(:overall_rating, :integer)
    field(:items_helpful, {:array, :string}, default: [])
    field(:items_not_helpful, {:array, :string}, default: [])
    field(:items_used, {:array, :string}, default: [])
    field(:missing_context, :string)
    field(:agent_id, :string)
    field(:session_id, :string)
    field(:metadata, :map, default: %{})

    timestamps()
  end

  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [
      :query_id,
      :query_text,
      :overall_rating,
      :items_helpful,
      :items_not_helpful,
      :items_used,
      :missing_context,
      :agent_id,
      :session_id,
      :metadata
    ])
    |> validate_number(:overall_rating,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 5,
      message: "must be between 1 and 5"
    )
  end
end
