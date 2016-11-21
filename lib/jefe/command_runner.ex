defmodule Jefe.CommandRunner do
  @moduledoc """
  Process responsible for the actual running of a command.
  """
  use GenServer
  require Logger

  alias Jefe.{Command, OutputRouter}

  @spec start_link(Command.t) :: {:ok, pid} | {:err, atom}
  def start_link(command) do
    GenServer.start_link(__MODULE__, command, name: proc_name(command))
  end

  @spec send_output(GenServer.server | String.t, String.t) :: :ok | no_return
  def send_output(name, output) when is_binary(name) do
    name |> proc_name |> send_output(output)
  end
  def send_output(server, output) do
    GenServer.call(server, {:send_output, output})
  end

  @spec os_pid(GenServer.server | String.t) :: pid | no_return
  def os_pid(name) when is_binary(name) do
    name |> proc_name |> os_pid
  end
  def os_pid(server) do
    GenServer.call(server, :os_pid)
  end

  @spec init(Command.t) :: {:ok, Command.t}
  def init(command) do
    {:ok, %{command: command, pid: nil}, 0}
  end

  def handle_call({:send_output, output}, _from, state) do
    :ok = :exec.send(state.pid, output)
    {:reply, :ok, state}
  end

  def handle_call(:os_pid, _from, state) do
    {:reply, state.pid, state}
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

  def handle_info({:DOWN, _, :process, _, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_info(msg, state) do
    Logger.debug("Unknown info message: #{inspect msg}")
    {:noreply, state}
  end

  @spec proc_name(Command.t | String.t) :: GenServer.server
  defp proc_name(%Command{name: name}), do: proc_name(name)
  defp proc_name(command_name) do
    {:via, :gproc, {:n, :l, {__MODULE__, command_name}}}
  end
end
