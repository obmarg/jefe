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

  test "forwards output to outputters subscribed to command name" do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "echo 'hello!'"}
    )
    OutputRouter.subscribe("test")
    assert_receive {:output, {:stdout, "hello!\r\n"}}
  end

  test "forwards output to outputters subscribed to all" do
    {:ok, pid} = Runner.start_link(
      %Command{name: "test", cmd: "echo 'hello!'"}
    )
    OutputRouter.subscribe
    assert_receive {:output, "test", {:stdout, "hello!\r\n"}}
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

  test "sending input to command" do
    {:ok, _} = Runner.start_link(
      %Command{name: "test", cmd: "read FIRSTWORD REST; echo $FIRSTWORD; sleep 1"}
    )
    OutputRouter.subscribe("test")

    Runner.send_output("test", "HELLO THERE!\n")
    assert_receive {:output, {:stdout, "HELLO\r\n"}}
  end
end
