defmodule Jefe.Spawner do
  @moduledoc """
  Tells the ProcessSupervisor to start a CommandRunner per Command.
  """
  use GenServer

  alias Jefe.Procfile

  def start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    Procfile.read
    |> Enum.each(&Supervisor.start_child(Jefe.CommandSupervisor, [&1]))

    {:ok, nil}
  end
end
