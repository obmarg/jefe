defmodule Jefe do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: :false

    command_worker = worker(Jefe.CommandRunner, [], restart: :permanent)

    children = [
      supervisor(
        Supervisor, [
          [supervisor(Supervisor, [[command_worker],
                                   [strategy: :simple_one_for_one,
                                    name: Jefe.CommandSupervisor]]),
           # death, but not at other times.
           worker(Jefe.Spawner, [], restart: :transient)],
          [strategy: :rest_for_one]
        ]
      ),
      worker(Jefe.ConsoleLogger, []),
      worker(Jefe.SSH.Server, [])
    ]

    opts = [strategy: :one_for_one, name: Jefe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
