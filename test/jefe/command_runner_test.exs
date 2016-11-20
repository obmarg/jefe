defmodule Jefe.CommandRunnerTest do
  use ExUnit.Case

  alias Jefe.{Command, OutputRouter}
  alias Jefe.CommandRunner, as: Runner

  test "runs command" do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "sleep 1"}
    )
    :timer.sleep(10)
    %{pid: os_pid} = :sys.get_state(pid)
    assert os_pid in :exec.which_children
    # TODO: Could do a `ps aux` if I really wanted...
  end

  test "forwards output to outputters" do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "echo 'hello!'"}
    )
    OutputRouter.subscribe("test")
    assert_receive {:output, {:stdout, "hello!\r\n"}}
  end

  test "dies if command does not exist" do
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: "test", cmd: "blargasdjsakdjad"}
    )
    :timer.sleep(50)
    refute Process.alive?(pid)
  end

  test "runner dies if command dies" do
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: "test", cmd: "echo 'hello!'"}
    )
    :timer.sleep(50)
    refute Process.alive?(pid)
  end

  test "command dies if runner dies" do
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: "test", cmd: "sleep 2"}
    )
    :timer.sleep(50)

    %{pid: os_pid} = :sys.get_state(pid)
    assert os_pid in :exec.which_children

    GenServer.stop(pid)
    :timer.sleep(50)
    refute os_pid in :exec.which_children
  end
end
