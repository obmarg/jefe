defmodule Jefe.Mixfile do
  use Mix.Project

  def project do
    [app: :jefe,
     version: "0.0.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: escript,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :erlexec, :ssh, :gproc, :timex],
      included_applications: [:recon, :dotenv],
      mod: {Jefe, []}
    ]
  end

  def escript do
    [main_module: Jefe.CLI,
     app: nil]
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
    [{:erlexec, github: "obmarg/erlexec"},
     {:gproc, "~> 0.6.1"},
     {:recon, "~> 2.2.1"},
     {:dotenv, "~> 2.1"},

     {:timex, "~> 3.0"},
     # Explicitly have to ask for tzdata 0.1.8 to work around this issue:
     # https://github.com/bitwalker/timex/issues/86
     {:tzdata, "~> 0.1.8", override: true}]
  end
end
