defmodule Jefe.SSH.Server do
  @moduledoc """
  Implements an SSH server that allows you to talk to a process running inside
  jefe.
  """
  use GenServer
  require Logger

  alias Jefe.SSH.ClientSession

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    {:ok, pid} = :ssh.daemon(
      {0,0,0,0},
      5867,
      shell: {__MODULE__, :spawn_session, [self]},
      user_passwords: [{'graeme', 'test'}],
      system_dir: '/Users/graeme/src/securi/test/test_ssh_keys'
    )
    true = Process.link(pid)
    {:ok, pid}
  end

  def spawn_session(server_pid) do
    {:ok, pid} = ClientSession.start_link
    pid
  end
end
