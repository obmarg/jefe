defmodule Jefe.ConsoleLogger do
  @moduledoc """
  Responsbile for logging the output of all commands to the console.
  """
  use GenServer
  require Logger

  alias Jefe.OutputRouter

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    OutputRouter.subscribe
    {:ok, nil}
  end

  def handle_info({:output, command_name, {_type, data}}, state) do
    # Lets output some really simple data initially...
    IO.write(data)
    {:noreply, state}
  end

  def handle_info(unknown, state) do
    Logger.warn "Unknown message received in ConsoleLogger: #{inspect unknown}"
  end
end
