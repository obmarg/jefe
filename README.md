# Jefe

A slightly advanced Foreman/Honcho clone in elixir.  Planned advanced features:

- Ability to SSH in to interact with running processes.
- Restarting processes on file changes.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add jefe to your list of dependencies in `mix.exs`:

        def deps do
          [{:jefe, "~> 0.0.1"}]
        end

  2. Ensure jefe is started before your application:

        def application do
          [applications: [:jefe]]
        end

