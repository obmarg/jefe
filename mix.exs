defmodule Jefe.Mixfile do
  use Mix.Project

  def project do
    [app: :jefe,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :erlexec, :ssh, :gproc],
      mod: {Jefe, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:erlexec, "~> 1.6.4"},
     {:gproc, "~> 0.6.1"},
     {:recon, "~> 2.2.1"}]
  end
end
