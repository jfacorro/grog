defmodule Grog.HTTP do
  require Logger
  require Grog.Utils
  alias Grog.Utils
  alias Grog.Metric.Server, as: Metric
  alias Grog.Metric.Count
  alias Grog.Metric.CountInterval
  alias Grog.Metric.Average
  alias Grog.Metric.Min
  alias Grog.Metric.Max
  alias Grog.Metric.Percentiles

  @timeout :infinity
  @opts %{report: true}

  def open(host, port) do
    {:ok, conn} = :shotgun.open(String.to_char_list(host), port)
    conn
  end

  def close(conn) do
    :shotgun.close(conn)
  end

  def get(conn, path, headers \\ %{}, opts \\ @opts) do
    request(conn, :get, path, "", headers, opts)
  end

  def post(conn, path, body, headers \\ %{}, opts \\ @opts) do
    request(conn, :post, path, body, headers, opts)
  end

  def delete(conn, path, body, headers \\ %{}, opts \\ @opts) do
    request(conn, :delete, path, body, headers, opts)
  end

  def put(conn, path, body, headers \\ %{}, opts \\ @opts) do
    request(conn, :put, path, body, headers, opts)
  end

  def options(conn, path, body, headers \\ %{}, opts \\ @opts) do
    request(conn, :options, path, body, headers, opts)
  end

  def head(conn, path, body, headers \\ %{}, opts \\ @opts) do
    request(conn, :head, path, body, headers, opts)
  end

  def request(conn, method, path, body, headers \\ %{}, opts \\ @opts) do
    path_str = String.to_char_list(path)
    opts = Map.put(opts, :timeout, @timeout)
    {time, value} = Utils.time(:shotgun.request(conn, method, path_str, headers, body, opts))
    if opts[:report] do
      report_general(time)
      key = opts[:name] || path
      case value do
        {:ok, %{status_code: status_code}} when status_code < 400 ->
          report_success(key, time)
        {:ok, %{status_code: status_code}} ->
          report_error(key, status_code)
        {:error, reason} ->
          report_error(:error, reason)
      end
    end

    value
  end

  ## Internal

  defp report_general(time_us) do
    key = "Total"
    Metric.report(key, %Count{name: "# Requests"}, 1)
    Metric.report(key, %CountInterval{name: "# Reqs/sec", interval: 1000}, 1)
    Metric.report(key, %Percentiles{name: "Percentiles"}, time_us)
  end

  defp report_success(key, time_us) do
    time_ms = time_us / 1000
    Metric.report(key, %Count{name: "# Requests"}, 1)
    Metric.report(key, %Average{name: "Average"}, time_ms)
    Metric.report(key, %Min{name: "Min"}, time_ms)
    Metric.report(key, %Max{name: "Max"}, time_ms)
    Metric.report(key, %CountInterval{name: "# Reqs/sec", interval: 1000}, 1)

    Metric.report(key, %Percentiles{name: "Percentiles"}, time_us)
  end

  defp report_error(key, status_code) do
    Metric.report(key, %Count{name: {:error, status_code}}, 1)
  end
end
