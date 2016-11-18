defmodule Jefe.CommandRunner do
  @moduledoc """
  Process responsible for the actual running of a command.
  """
  use GenServer
  require Logger

  alias Jefe.{Command, OutputRouter}

  @spec start_link(Command.t) :: {:ok, pid} | {:err, atom}
  def start_link(command) do
    GenServer.start_link(__MODULE__, command)
  end

  @spec init(Command.t) :: {:ok, Command.t}
  def init(command) do
    {:ok, %{command: command, pid: nil}, 0}
  end

  def handle_info(:timeout, state = %{command: %{cmd: cmd}}) do
    {:ok, pid, os_pid} = :exec.run_link(
      cmd |> String.to_char_list, [:stdout, :stderr, :stdin, :pty]
    )

    # Ideally I'd like to link to the erlexec process, but that doesn't
    # seem to work.  So, monitoring it is!
    Process.monitor(pid)

    # TODO: should i store the pid here for future matching?
    {:noreply, %{state | pid: os_pid}}
  end

  def handle_info({:stdout, pid, data}, %{pid: pid} = state) do
    OutputRouter.stdout(state.command.name, data)
    {:noreply, state}
  end

  def handle_info({:stderr, pid, data}, %{pid: pid} = state) do
    OutputRouter.stderr(state.command.name, data)
    {:noreply, state}
  end

  def handle_info({:DOWN, _, :process, _, reason}, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Unknown info message: #{inspect msg}")
    {:noreply, state}
  end
end
