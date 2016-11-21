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
    File.mkdir_p!(system_dir)
    gen_key("ssh_host_rsa_key", "rsa")
    gen_key("ssh_host_dsa_key", "dsa")

    {:ok, pid} = :ssh.daemon(
      {0,0,0,0},
      5867,
      shell: &spawn_session/1,
      # TODO: Ideally we should be able to generate our own ssh keys
      # on startup if there aren't already some in place...
      system_dir: system_dir |> String.to_charlist,
      auth_methods: 'publickey'
    )
    true = Process.link(pid)
    {:ok, pid}
  end

  def spawn_session(username) do
    {:ok, pid} =
      username
      |> List.to_string
      |> ClientSession.start_link

    pid
  end

  # The path to our SSH servers system directory.
  defp system_dir do
    Path.expand("~/.jefe/ssh_server/")
  end

  # Generates an SSH key of the provided type in system_dir
  defp gen_key(filename, type) do
    unless File.exists?(Path.join(system_dir, filename)) do
      {_output, 0} = System.cmd(
        "ssh-keygen",
        ["-f", filename, "-N", "", "-t", type],
        cd: system_dir
      )
    end
  end
end
