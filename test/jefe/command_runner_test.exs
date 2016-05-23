defmodule Jefe.CommandRunnerTest do
  use ExUnit.Case

  alias Jefe.{Command, OutputHandler}
  alias Jefe.CommandRunner, as: Runner

  setup do
    {:ok, outputter} = OutputHandler.start_link
    {:ok, %{outputter: outputter}}
  end

  test "runs command", %{outputter: outputter} do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "sleep 1"},
      outputter
    )
    :timer.sleep(500)
    %{pid: os_pid} = :sys.get_state(pid)
    assert os_pid in :exec.which_children
    # TODO: Could do a `ps aux` if I really wanted...
  end

  test "forwards output to outputter", %{outputter: outputter} do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "echo 'hello!'"},
      outputter
    )
    :timer.sleep(100)
    assert OutputHandler.stdout(outputter) == "hello!\n"
  end

  test "dies if command does not exist", %{outputter: outputter} do
    {:ok, pid} = GenServer.start(
      Runner,
      {%Command{name: "test", cmd: "blargasdjsakdjad"}, outputter}
    )
    :timer.sleep(500)
    refute Process.alive?(pid)
  end

  test "runner dies if command dies", %{outputter: outputter} do
    {:ok, pid} = GenServer.start(
      Runner,
      {%Command{name: "test", cmd: "echo 'hello!'"}, outputter}
    )
    :timer.sleep(500)
    refute Process.alive?(pid)
  end

  test "command dies if runner dies", %{outputter: outputter} do
    {:ok, pid} = GenServer.start(
      Runner,
      {%Command{name: "test", cmd: "sleep 2"}, outputter}
    )
    :timer.sleep(500)

    %{pid: os_pid} = :sys.get_state(pid)
    assert os_pid in :exec.which_children

    GenServer.stop(pid)
    :timer.sleep(500)
    refute os_pid in :exec.which_children
  end
end
