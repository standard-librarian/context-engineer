defmodule ContextEngineering.Services.EmbeddingService do
  @moduledoc """
  Generates vector embeddings for text using Bumblebee (local ML models).
  Loads the model once at startup and holds it in GenServer state.
  """

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_state) do
    {:ok, model_info} = Bumblebee.load_model({:hf, "sentence-transformers/all-MiniLM-L6-v2"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "sentence-transformers/all-MiniLM-L6-v2"})

    serving =
      Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer,
        defn_options: [compiler: EXLA]
      )

    {:ok, %{serving: serving}}
  end

  @doc """
  Generate embedding for a text string.
  Returns {:ok, list_of_floats}.
  """
  def generate_embedding(text) when is_binary(text) do
    GenServer.call(__MODULE__, {:generate, text}, 30_000)
  end

  @doc """
  Batch generate embeddings for multiple texts.
  Returns {:ok, list_of_embeddings}.
  """
  def batch_generate_embeddings(texts) when is_list(texts) do
    GenServer.call(__MODULE__, {:batch_generate, texts}, 60_000)
  end

  def handle_call({:generate, text}, _from, %{serving: serving} = state) do
    output = Nx.Serving.run(serving, text)
    embedding = output.embedding |> Nx.to_flat_list()
    {:reply, {:ok, embedding}, state}
  end

  def handle_call({:batch_generate, texts}, _from, %{serving: serving} = state) do
    embeddings =
      Enum.map(texts, fn text ->
        output = Nx.Serving.run(serving, text)
        output.embedding |> Nx.to_flat_list()
      end)

    {:reply, {:ok, embeddings}, state}
  end
end
