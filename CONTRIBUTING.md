# Contributing to Context Engineering

Thank you for your interest in contributing to Context Engineering! This guide will help you get started with development, understand the project structure, and make meaningful contributions.

##  Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Style](#code-style)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Project Structure](#project-structure)
- [Common Tasks](#common-tasks)

##  Getting Started

### Prerequisites

- Elixir 1.15+ and Erlang/OTP 26+
- PostgreSQL 14+ with pgvector extension
- Git
- 2GB+ RAM for ML models

### Setup

1. **Fork and clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/context-engineer.git
   cd context-engineer/context_engineering
   ```

2. **Install dependencies**
   ```bash
   mix deps.get
   ```

3. **Setup database**
   ```bash
   mix setup
   ```

4. **Run tests to verify setup**
   ```bash
   mix test
   ```

5. **Start the server**
   ```bash
   mix phx.server
   ```

Visit http://localhost:4000 to verify everything works.

##  Development Workflow

### Before You Start

1. **Check existing issues**: Look for an existing issue or create a new one
2. **Discuss significant changes**: For major features, open an issue first to discuss the approach
3. **Create a branch**: Use descriptive names like `feat/semantic-filters` or `fix/embedding-timeout`

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make your changes** following the [Code Style](#code-style) guidelines

3. **Write tests** for your changes

4. **Run the precommit checks**
   ```bash
   mix precommit
   ```
   This runs:
   - Code compilation with warnings as errors
   - Unused dependency check
   - Code formatting
   - All tests

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add semantic filtering by date range"
   ```

   Use conventional commit format:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `test:` - Test additions or fixes
   - `refactor:` - Code refactoring
   - `perf:` - Performance improvements
   - `chore:` - Build process or auxiliary tool changes

6. **Push to your fork**
   ```bash
   git push origin feat/your-feature-name
   ```

7. **Open a Pull Request** with a clear description of changes

##  Code Style

### Elixir Style Guide

We follow the standard Elixir style guide with Phoenix conventions. Key points:

#### Formatting

- **Always run `mix format` before committing**
- Line length: 98 characters (configured in `.formatter.exs`)
- Use 2 spaces for indentation

#### Naming Conventions

```elixir
# Module names: PascalCase
defmodule ContextEngineering.Services.SearchService do
end

# Function names: snake_case
def create_adr(params) do
end

# Private functions: prefix with underscore
defp maybe_add_tags(params) do
end

# Predicate functions: end with ?
def valid?(changeset) do
end

# Dangerous functions: end with !
def get_adr!(id) do
end
```

#### Documentation

**All public functions MUST have `@doc` annotations:**

```elixir
@doc """
Creates a new ADR with automatic embedding generation.

## Parameters

  - `params` - Map with required keys: "title", "decision", "context"

## Returns

  - `{:ok, %ADR{}}` on success
  - `{:error, %Ecto.Changeset{}}` on validation failure

## Examples

    iex> create_adr(%{"title" => "Use PostgreSQL", ...})
    {:ok, %ADR{id: "ADR-001"}}

"""
def create_adr(params) do
  # implementation
end
```

**All modules MUST have `@moduledoc` annotations:**

```elixir
defmodule MyModule do
  @moduledoc """
  Brief description of what this module does.

  Longer explanation with usage examples and architecture notes.
  """
end
```

#### Pattern Matching

**Prefer pattern matching over conditional logic:**

```elixir
# Good
def handle_result({:ok, value}), do: process(value)
def handle_result({:error, reason}), do: log_error(reason)

# Avoid
def handle_result(result) do
  if result[:ok] do
    process(result[:value])
  else
    log_error(result[:error])
  end
end
```

#### Pipes and Composition

**Use pipes for transformation chains:**

```elixir
# Good
params
|> maybe_add_tags()
|> ADR.changeset()
|> Repo.insert()

# Avoid
Repo.insert(ADR.changeset(maybe_add_tags(params)))
```

#### Error Handling

**Use tagged tuples `{:ok, result}` or `{:error, reason}`:**

```elixir
# Good
def get_adr(id) do
  case Repo.get(ADR, id) do
    nil -> {:error, :not_found}
    adr -> {:ok, adr}
  end
end

# For functions that should raise, use ! suffix
def get_adr!(id) do
  Repo.get!(ADR, id)
end
```

### Phoenix-Specific Guidelines

#### Controllers

- Keep controllers thin - business logic belongs in context modules
- Use actions: `index`, `show`, `create`, `update`, `delete`
- Return JSON with proper HTTP status codes

```elixir
def query(conn, %{"query" => query_text} = params) do
  max_tokens = Map.get(params, "max_tokens", 4000)
  
  case BundlerService.bundle_context(query_text, max_tokens: max_tokens) do
    {:ok, bundle} ->
      conn
      |> put_status(:ok)
      |> json(bundle)
      
    {:error, reason} ->
      conn
      |> put_status(:bad_request)
      |> json(%{error: reason})
  end
end
```

#### Context Modules

- Business logic lives in context modules (like `Knowledge`)
- Contexts are the public API for your domain
- Contexts call Ecto directly, controllers call contexts

#### Schemas

- Use `@derive {Jason.Encoder, only: [...]}` to control JSON serialization
- Add `with_embedding/2` helper for setting embeddings
- Include comprehensive field documentation in `@moduledoc`

##  Testing

### Writing Tests

**Test files mirror source structure:**
```
lib/context_engineering/knowledge.ex
test/context_engineering/knowledge_test.exs
```

**Use descriptive test names:**

```elixir
defmodule ContextEngineering.KnowledgeTest do
  use ContextEngineering.DataCase
  
  alias ContextEngineering.Knowledge
  
  describe "create_adr/1" do
    test "creates ADR with valid attributes" do
      params = %{
        "title" => "Use PostgreSQL",
        "decision" => "We will use PostgreSQL",
        "context" => "We need ACID guarantees"
      }
      
      assert {:ok, adr} = Knowledge.create_adr(params)
      assert adr.title == "Use PostgreSQL"
      assert String.starts_with?(adr.id, "ADR-")
    end
    
    test "returns error with invalid attributes" do
      params = %{"title" => "Missing required fields"}
      
      assert {:error, changeset} = Knowledge.create_adr(params)
      assert %{decision: ["can't be blank"]} = errors_on(changeset)
    end
    
    test "generates embeddings automatically" do
      params = valid_adr_params()
      
      assert {:ok, adr} = Knowledge.create_adr(params)
      assert is_list(adr.embedding)
      assert length(adr.embedding) == 384
    end
  end
end
```

### Running Tests

```bash
# Run all tests
mix test

# Run specific file
mix test test/context_engineering/knowledge_test.exs

# Run specific test
mix test test/context_engineering/knowledge_test.exs:42

# Run with coverage
mix test --cover

# Run only failed tests
mix test --failed

# Run in watch mode (requires mix_test_watch)
mix test.watch
```

### Test Guidelines

- **Always use `start_supervised!/1`** for starting processes in tests (automatic cleanup)
- **Avoid `Process.sleep/1`** - use `Process.monitor/1` and assert on messages instead
- **Use factories or fixtures** for test data (consider adding ExMachina)
- **Test happy path AND error cases**
- **Mock external dependencies** (though we use local ML models)

##  Documentation

### Code Documentation

- **Every public function** needs a `@doc` annotation
- **Every module** needs a `@moduledoc` annotation
- Use **examples** in documentation
- Include **parameter descriptions** and **return values**

### Generating Docs

```bash
# Generate HTML documentation
mix docs

# Open in browser
open doc/index.html
```

### README Updates

When adding new features:
- Update the main README.md with usage examples
- Update API reference section if adding new endpoints
- Add to the "Core Concepts" section if introducing new concepts

##  Submitting Changes

### Pull Request Checklist

Before submitting a PR, ensure:

- [ ] Code compiles without warnings (`mix compile --warnings-as-errors`)
- [ ] All tests pass (`mix test`)
- [ ] Code is formatted (`mix format --check-formatted`)
- [ ] No unused dependencies (`mix deps.unlock --unused`)
- [ ] Documentation is updated (code docs and README if applicable)
- [ ] `mix precommit` passes
- [ ] Commit messages follow conventional commit format
- [ ] PR description explains what and why, not just how

### Pull Request Template

```markdown
## Description
Brief description of changes

## Motivation
Why is this change needed?

## Changes
- List of key changes
- Bullet points work well

## Testing
How was this tested?

## Screenshots (if applicable)
Add screenshots for UI changes

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] `mix precommit` passes
```

### Review Process

1. Maintainers will review your PR within 1-2 weeks
2. Address feedback in new commits (don't force push during review)
3. Once approved, a maintainer will merge your PR
4. Your contribution will be credited in release notes

##  Project Structure

```
context_engineering/
 lib/
    context_engineering/
       application.ex              # OTP application setup
       repo.ex                     # Ecto repository
       knowledge.ex                # Main context/API
       contexts/                   # Domain contexts
          adrs/                   # ADR schema & logic
          failures/               # Failure schema & logic
          meetings/               # Meeting schema & logic
          snapshots/              # Snapshot schema & logic
          relationships/          # Graph relationships
       services/                   # Business services
          embedding_service.ex    # ML embeddings (GenServer)
          search_service.ex       # Semantic search
          bundler_service.ex      # Context bundling
       events/                     # Event processing
          event_processor.ex      # External event handling
          log_parser.ex           # Log ingestion
       workers/                    # Background jobs
           decay_worker.ex         # Relevance decay
    context_engineering_web/        # Phoenix web layer
       controllers/                # HTTP controllers
       router.ex                   # Route definitions
       endpoint.ex                 # HTTP endpoint config
    mix/
        tasks/                      # Mix CLI tasks
            context.adr.ex
            context.failure.ex
            context.query.ex
            ...
 test/                               # Test files (mirrors lib/)
 priv/
    repo/
        migrations/                 # Database migrations
        seeds.exs                   # Seed data
 config/                             # Configuration files
 mix.exs                             # Project definition
 README.md                           # Main documentation
```

##  Common Tasks

### Adding a New Knowledge Type

Let's say you want to add "Experiments" as a new knowledge type:

1. **Create the schema**
   ```bash
   mkdir -p lib/context_engineering/contexts/experiments
   ```
   
   Create `lib/context_engineering/contexts/experiments/experiment.ex`:
   ```elixir
   defmodule ContextEngineering.Contexts.Experiments.Experiment do
     @moduledoc """
     Schema for A/B test experiments and results.
     """
     use Ecto.Schema
     import Ecto.Changeset
     
     @primary_key {:id, :string, autogenerate: false}
     schema "experiments" do
       field :title, :string
       field :hypothesis, :string
       field :result, :string
       field :tags, {:array, :string}, default: []
       field :embedding, Pgvector.Ecto.Vector
       
       timestamps()
     end
     
     def changeset(experiment, attrs) do
       experiment
       |> cast(attrs, [:id, :title, :hypothesis, :result, :tags])
       |> validate_required([:id, :title, :hypothesis])
     end
     
     def with_embedding(changeset, embedding) do
       put_change(changeset, :embedding, embedding)
     end
   end
   ```

2. **Create migration**
   ```bash
   mix ecto.gen.migration create_experiments
   ```
   
   Edit the migration file:
   ```elixir
   def change do
     create table(:experiments, primary_key: false) do
       add :id, :string, primary_key: true
       add :title, :string, null: false
       add :hypothesis, :text
       add :result, :text
       add :tags, {:array, :string}, default: []
       add :embedding, :vector, size: 384
       
       timestamps()
     end
     
     create index(:experiments, [:embedding], using: "hnsw", opclass: :vector_cosine_ops)
   end
   ```

3. **Add to Knowledge context**
   
   Add functions to `lib/context_engineering/knowledge.ex`:
   ```elixir
   def create_experiment(params) do
     # Similar to create_adr/1
   end
   
   def get_experiment(id), do: # ...
   def list_experiments(params \\ %{}), do: # ...
   def update_experiment(id, params), do: # ...
   ```

4. **Add to SearchService**
   
   Add `:experiment` to search types and implement `search_by_type(:experiment, ...)`

5. **Add to BundlerService**
   
   Add `hydrate_item(id, "experiment")` function

6. **Create Mix task**
   
   Create `lib/mix/tasks/context.experiment.ex`

7. **Add tests**
   
   Create `test/context_engineering/knowledge_test.exs` tests for experiments

8. **Update documentation**
   
   Add experiments to README.md and relevant docs

### Adding a New API Endpoint

1. **Add route** in `lib/context_engineering_web/router.ex`
2. **Create controller action** in appropriate controller
3. **Add tests** in `test/context_engineering_web/controllers/`
4. **Update API documentation** in README.md

### Debugging Tips

**IEx debugging:**
```elixir
# In your code, add:
require IEx; IEx.pry()

# Run tests with IEx:
iex -S mix test --trace
```

**Inspect queries:**
```elixir
import Ecto.Query
alias ContextEngineering.Repo

query = from(a in ADR, where: a.status == "active")
IO.inspect(Repo.to_sql(:all, query))
```

**Check embeddings:**
```elixir
alias ContextEngineering.Services.EmbeddingService

{:ok, embedding} = EmbeddingService.generate_embedding("test")
IO.inspect(length(embedding))  # Should be 384
```

##  Questions?

- Open an issue for bugs or feature requests
- Check existing issues before creating new ones
- Join discussions on open PRs and issues

##  License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Context Engineering! 