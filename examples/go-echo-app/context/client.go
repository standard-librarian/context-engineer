package context

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"time"
)

type Client struct {
	BaseURL string
	client  *http.Client
}

func NewClient(baseURL string) *Client {
	return &Client{
		BaseURL: baseURL,
		client:  &http.Client{Timeout: 10 * time.Second},
	}
}

type QueryRequest struct {
	Query     string   `json:"query"`
	MaxTokens int      `json:"max_tokens,omitempty"`
	Domains   []string `json:"domains,omitempty"`
}

type QueryResponse struct {
	KeyDecisions  []Decision `json:"key_decisions"`
	KnownIssues   []Issue    `json:"known_issues"`
	RecentChanges []Change   `json:"recent_changes"`
	TotalItems    int        `json:"total_items"`
}

type Decision struct {
	ID       string   `json:"id"`
	Title    string   `json:"title"`
	Decision string   `json:"decision"`
	Tags     []string `json:"tags"`
	Score    float64  `json:"score"`
}

type Issue struct {
	ID         string   `json:"id"`
	Title      string   `json:"title"`
	RootCause  string   `json:"root_cause"`
	Resolution string   `json:"resolution"`
	Pattern    string   `json:"pattern"`
	Tags       []string `json:"tags"`
}

type Change struct {
	ID    string   `json:"id"`
	Type  string   `json:"type"`
	Title string   `json:"title"`
	Tags  []string `json:"tags"`
}

func (c *Client) Query(req QueryRequest) (*QueryResponse, error) {
	body, err := json.Marshal(req)
	if err != nil {
		return nil, fmt.Errorf("marshal request: %w", err)
	}

	resp, err := c.client.Post(
		c.BaseURL+"/context/query",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return nil, fmt.Errorf("http post: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	var result QueryResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("decode response: %w", err)
	}

	return &result, nil
}

type ADRRequest struct {
	Title             string              `json:"title"`
	Decision          string              `json:"decision"`
	Context           string              `json:"context"`
	OptionsConsidered map[string][]string `json:"options_considered,omitempty"`
	Tags              []string            `json:"tags,omitempty"`
	Stakeholders      []string            `json:"stakeholders,omitempty"`
}

func (c *Client) CreateADR(req ADRRequest) error {
	body, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	resp, err := c.client.Post(
		c.BaseURL+"/adr",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("http post: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	return nil
}

type FailureRequest struct {
	Title      string   `json:"title"`
	RootCause  string   `json:"root_cause"`
	Symptoms   string   `json:"symptoms"`
	Impact     string   `json:"impact"`
	Resolution string   `json:"resolution"`
	Prevention []string `json:"prevention,omitempty"`
	Severity   string   `json:"severity"`
	Pattern    string   `json:"pattern,omitempty"`
	Tags       []string `json:"tags,omitempty"`
}

func (c *Client) RecordFailure(req FailureRequest) error {
	body, err := json.Marshal(req)
	if err != nil {
		return fmt.Errorf("marshal request: %w", err)
	}

	resp, err := c.client.Post(
		c.BaseURL+"/failure",
		"application/json",
		bytes.NewReader(body),
	)
	if err != nil {
		return fmt.Errorf("http post: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected status: %d", resp.StatusCode)
	}

	return nil
}
