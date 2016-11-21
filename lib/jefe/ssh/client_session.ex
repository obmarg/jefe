defmodule Jefe.SSH.ClientSession do
  @moduledoc """
  GenServer that handles a single clients connection to the jefe ssh server.
  """
  use GenServer

  alias Jefe.{Command, CommandRunner, OutputRouter}

  def start_link(command_name) do
    GenServer.start_link(__MODULE__, command_name)
  end

  def init(command_name) do
    :ok = OutputRouter.subscribe(command_name)
    spawn_link(fn -> read_client_input(command_name) end)
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
