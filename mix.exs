defmodule GenMetrics.Mixfile do
  use Mix.Project

  def project do
    [app: :gen_metrics,
     version: "0.2.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),
     aliases: aliases(),
     docs: [main: "GenMetrics", source_url: "https://github.com/onetapbeyond/gen_metrics"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {GenMetrics.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:gen_stage, "~> 0.11"},
     {:statix, ">= 0.0.0"},
     {:ex_doc, "~> 0.14", only: :dev, runtime: false},
     {:credo, "~> 0.7", only: [:dev, :test]},
     {:benchee, "~> 0.7", only: :dev}]
  end

  defp aliases do
    [trace_cluster: "run ./bench/trace_cluster.exs",
     sample_cluster: "run ./bench/sample_cluster.exs",
     trace_pipeline: "run ./bench/trace_pipeline.exs",
     sample_pipeline: "run ./bench/sample_pipeline.exs"]
  end

  defp description do
    """
    Elixir GenServer and GenStage runtime metrics.
    """
  end

  defp package do
    [
      name: :gen_metrics,
      maintainers: ["David Russell"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/onetapbeyond/gen_metrics"}
    ]
  end

end
