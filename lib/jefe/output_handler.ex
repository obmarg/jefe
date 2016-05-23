defmodule Jefe.OutputHandler do
  @moduledoc """
  Routes output from a process into anywhere that needs it.

  Currently this is just an Agent that stores the data, but we can change it later.
  """
  def start_link() do
    Agent.start_link(fn -> %{stdout: [], stderr: []} end)
  end

  @spec stdout(pid) :: String.t
  def stdout(pid), do: get_output(pid, :stdout)

  @spec stdout(pid, String.t) :: :ok
  def stdout(pid, data), do: add_output(pid, :stdout, data)

  @spec stderr(pid) :: String.t
  def stderr(pid), do: get_output(pid, :stderr)

  @spec stderr(pid, String.t) :: :ok
  def stderr(pid, data), do: add_output(pid, :stderr, data)

  @spec add_output(pid, :stdout | :stderr, String.t) :: :ok 
  defp add_output(pid, type, data) do
    Agent.update(
      pid, &Map.update!(&1, type, fn existing -> [data|existing] end)
    )
  end

  @spec get_output(pid, :stdout | :stderr) :: String.t
  defp get_output(pid, type) do
    pid
    |> Agent.get(fn %{^type => data} -> data end)
    |> Enum.reverse
    |> Enum.join
  end
end
