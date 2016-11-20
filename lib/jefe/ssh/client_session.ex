defmodule Jefe.SSH.ClientSession do
  @moduledoc """
  GenServer that handles a single clients connection to the jefe ssh server.
  """
  use GenServer

  alias Jefe.{Command, CommandRunner, OutputRouter}

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    {:ok, command_runner} = CommandRunner.start_link(
      %Command{name: "python", cmd: "python"}
    )
    :ok = OutputRouter.subscribe("python")
    spawn_link(fn -> read_client_input("python") end)
    {:ok, nil}
  end

  def handle_info({:output, {:stderr, data}}, state) do
    IO.write(:stderr, data)
    {:noreply, state}
  end

  def handle_info({:output, {:stdout, data}}, state) do
    IO.write(data)
    {:noreply, state}
  end

  defp read_client_input(command_name) do
    data = :line |> IO.read |> IO.chardata_to_string
    CommandRunner.send_output(command_name, data)
    read_client_input(command_name)
  end
end
