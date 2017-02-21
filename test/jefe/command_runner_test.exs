defmodule Jefe.CommandRunnerTest do
  use ExUnit.Case

  alias Jefe.{Command, OutputRouter}
  alias Jefe.CommandRunner, as: Runner

  test "runs command" do
    name = name()
    {:ok, _pid} = Runner.start_link(
      %Command{name: name, cmd: "sleep 1"}
    )
    :timer.sleep(10)
    os_pid = Runner.os_pid(name)
    assert os_pid in :exec.which_children
    # TODO: Could do a `ps aux` if I really wanted...
  end

  test "forwards output to outputters subscribed to command name" do
    name = name()
    {:ok, _pid} = Runner.start_link(
      %Command{name: name, cmd: "echo 'hello!'"}
    )
    OutputRouter.subscribe( name)
    assert_receive {:output, {:stdout, "hello!\r\n"}}
  end

  test "forwards output to outputters subscribed to all" do
    name = name()
    {:ok, _pid} = Runner.start_link(
      %Command{name: name, cmd: "echo 'hello!'"}
    )
    OutputRouter.subscribe
    assert_receive {:output, ^name, {:stdout, "hello!\r\n"}}
  end

  test "dies if command does not exist" do
    name = name()
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: name, cmd: "blargasdjsakdjad"}
    )
    :timer.sleep(50)
    refute Process.alive?(pid)
  end

  test "runner dies if command dies" do
    name = name()
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: name, cmd: "echo 'hello!'"}
    )
    :timer.sleep(50)
    refute Process.alive?(pid)
  end

  test "command dies if runner dies" do
    name = name()
    {:ok, pid} = GenServer.start(
      Runner,
      %Command{name: name, cmd: "sleep 2"}
    )
    :timer.sleep(50)

    os_pid = Runner.os_pid(pid)
    assert os_pid in :exec.which_children

    GenServer.stop(pid)
    :timer.sleep(50)
    refute os_pid in :exec.which_children
  end

  test "sending input to command" do
    name = name()
    {:ok, _} = Runner.start_link(
      %Command{name: name, cmd: "read FIRSTWORD REST; echo $FIRSTWORD; sleep 1"}
    )
    OutputRouter.subscribe(name)

    Runner.send_output(name, "HELLO THERE!\n")
    assert_receive {:output, {:stdout, "HELLO\r\n"}}
  end

  defp name() do
    "test-#{random_string(3)}"
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end
end
