defmodule Jefe.OutputRouter do
  @moduledoc """
  Routes output from a process into anywhere that needs it.
  """

  @opaque key :: :gproc.key

  @doc """
  Routes stdout to any listening processes.
  """
  @spec stdout(key, String.t) :: String.t
  def stdout(key, data) do
    key |> addr |> :gproc.send({:output, {:stdout, data}})
  end

  @doc """
  Routes stderr to any listening processes.
  """
  @spec stderr(key, String.t) :: String.t
  def stderr(key, data) do
    key |> addr |> :gproc.send({:output, {:stderr, data}})
  end

  @doc """
  Subscribes the current process to output from the provided topic.
  """
  @spec subscribe(atom) :: :ok
  def subscribe(topic) do
    topic |> addr |> :gproc.reg
    :ok
  end

  defp addr(topic) do
    {:p, :l, {__MODULE__, topic}}
  end
end
