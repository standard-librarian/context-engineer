defmodule ContextEngineeringWeb.Router do
  use ContextEngineeringWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ContextEngineeringWeb do
    pipe_through(:api)

    # ADRs
    post("/adr", ADRController, :create)
    get("/adr/:id", ADRController, :show)
    get("/adr", ADRController, :index)
    put("/adr/:id", ADRController, :update)

    # Failures
    post("/failure", FailureController, :create)
    get("/failure/:id", FailureController, :show)
    get("/failure", FailureController, :index)
    put("/failure/:id", FailureController, :update)

    # Meetings
    post("/meeting", MeetingController, :create)
    get("/meeting/:id", MeetingController, :show)
    get("/meeting", MeetingController, :index)
    put("/meeting/:id", MeetingController, :update)

    # Context Query (main endpoint)
    post("/context/query", ContextController, :query)
    get("/context/domain/:name", ContextController, :domain)
    get("/context/recent", ContextController, :recent)
    get("/context/timeline", ContextController, :timeline)
    post("/context/snapshot", ContextController, :snapshot)

    # Language-agnostic event ingestion (Go, Python, Node.js, Java, etc.)
    post("/events/error", EventController, :error)
    post("/events/deploy", EventController, :deploy)
    post("/events/metric", EventController, :metric)

    # Log streaming (Fluentd, Logstash, direct POST)
    post("/logs/stream", LogController, :ingest)

    # Graph
    get("/graph/related/:id", GraphController, :related)
    get("/graph/export", GraphController, :export)

    # Feedback
    post("/feedback", FeedbackController, :create)
    get("/feedback", FeedbackController, :index)
    get("/feedback/stats", FeedbackController, :stats)
    get("/feedback/:id", FeedbackController, :show)

    # Auto-remediation
    post("/remediate", RemediationController, :create)
  end

  # Browser routes for graph visualization
  scope "/", ContextEngineeringWeb do
    get("/graph", GraphController, :visualize)
    get("/graph/obsidian", GraphObsidianController, :visualize)
    get("/graph/excalidraw", GraphExcalidrawController, :visualize)
  end
end
