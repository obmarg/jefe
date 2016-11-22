defmodule Jefe.SSH.ClientSession do
  @moduledoc """
  GenServer that handles a single clients connection to the jefe ssh server.
  """
  use GenServer
  require Logger

  alias Jefe.{CommandRunner, OutputRouter}

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
    case read do
      {:ok, data} ->
        CommandRunner.send_output(command_name, data)
        read_client_input(command_name)
      {:done, _reason} ->
        nil
      {:error, err} ->
        Logger.error(err)
    end
  end

  defp read do
    case IO.read(:line) do
      :eof -> {:done, :eof}
      {:error, :interrupted} -> {:done, :interrupted}
      {:error, other} -> {:error, other}
      data -> {:ok, IO.chardata_to_string(data)}
    end
  end
end
