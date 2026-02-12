defmodule ContextEngineering.Services.EmbeddingService do
  @moduledoc """
  Generates vector embeddings for text using Bumblebee (local ML models).

  This service is the core of Context Engineering's semantic search capabilities.
  It converts text into numerical vectors (embeddings) that capture semantic meaning,
  allowing the system to find conceptually similar content even when different words are used.

  ## What are Embeddings?

  Embeddings are lists of floating-point numbers (vectors) that represent the semantic
  meaning of text. Similar concepts produce similar vectors, which can be compared using
  mathematical operations like cosine similarity.

  **Example:**
  - "database failure" → [0.23, -0.45, 0.67, ...]
  - "DB outage" → [0.21, -0.43, 0.65, ...]  (very similar vector!)
  - "user interface" → [-0.89, 0.12, -0.34, ...] (completely different vector)

  ## Architecture

  This module runs as a **GenServer** (Elixir's process for maintaining state) that:

  1. **Loads the ML model once at startup** - The `sentence-transformers/all-MiniLM-L6-v2`
     model is loaded from Hugging Face and kept in memory
  2. **Serves embedding requests** - Handles synchronous calls to generate embeddings
  3. **Uses EXLA for acceleration** - Compiles tensor operations for fast execution
  4. **No external API calls** - Everything runs locally, no OpenAI/API keys needed

  ## Model Details

  - **Model**: `sentence-transformers/all-MiniLM-L6-v2`
  - **Embedding size**: 384 dimensions
  - **Speed**: ~100-200 texts/second on modern hardware
  - **Quality**: Good balance of speed and accuracy for semantic search
  - **Local**: Runs entirely on your server via Bumblebee + Nx + EXLA

  ## Usage

  The service is started automatically by the Application supervisor.
  Other modules call it to generate embeddings:

      iex> EmbeddingService.generate_embedding("Why did we choose PostgreSQL?")
      {:ok, [0.023, -0.145, 0.267, ...]}  # 384 float values

      iex> EmbeddingService.batch_generate_embeddings([
      ...>   "database failure",
      ...>   "user authentication bug",
      ...>   "API rate limiting"
      ...> ])
      {:ok, [[0.1, ...], [0.2, ...], [0.3, ...]]}

  ## Performance Considerations

  - **First call is slow** (~2-5 seconds) as the model compiles
  - **Subsequent calls are fast** (~10-50ms per text)
  - **Batch processing** is more efficient for multiple texts
  - **GenServer call timeout**: 30 seconds for single, 60 seconds for batch

  ## Integration

  Called by:
  - `Knowledge.create_adr/1` - Embeds ADR content
  - `Knowledge.create_failure/1` - Embeds failure descriptions
  - `Knowledge.create_meeting/1` - Embeds meeting decisions
  - `SearchService.search/2` - Embeds search queries for comparison
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
  Generates a vector embedding for a single text string.

  Converts text into a 384-dimensional vector that captures its semantic meaning.
  The same or similar text will always produce similar vectors.

  ## Parameters

    - `text` - String to embed (any length, but optimal is 1-512 words)

  ## Returns

    - `{:ok, [float]}` - List of 384 floating-point numbers representing the embedding

  ## Examples

      iex> EmbeddingService.generate_embedding("PostgreSQL database")
      {:ok, [0.023, -0.145, 0.267, ...]}  # 384 values

      iex> EmbeddingService.generate_embedding("")
      {:ok, [0.0, 0.0, ...]}  # Empty text produces zero vector

  ## Performance

  - First call: ~2-5 seconds (model compilation)
  - Subsequent calls: ~10-50ms
  - Timeout: 30 seconds

  """
  def generate_embedding(text) when is_binary(text) do
    GenServer.call(__MODULE__, {:generate, text}, 30_000)
  end

  @doc """
  Generates embeddings for multiple texts in a batch.

  More efficient than calling `generate_embedding/1` multiple times,
  especially for large batches.

  ## Parameters

    - `texts` - List of strings to embed

  ## Returns

    - `{:ok, [[float]]}` - List of embeddings (each embedding is a list of 384 floats)

  ## Examples

      iex> texts = ["database failure", "API timeout", "memory leak"]
      iex> {:ok, embeddings} = EmbeddingService.batch_generate_embeddings(texts)
      iex> length(embeddings)
      3
      iex> length(hd(embeddings))
      384

  ## Performance

  - Processes texts sequentially (currently not parallelized)
  - Timeout: 60 seconds
  - For 100 texts: ~3-5 seconds

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
