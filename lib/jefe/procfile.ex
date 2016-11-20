defmodule Jefe.Procfile do
  @moduledoc """
  Provides functions for parsing Procfiles in Elixir.
  """
  alias Jefe.Command

  @doc """
  Reads and parses a file named Procfile.
  """
  @spec read :: [Command.t]
  def read, do: "Procfile" |> File.read! |> parse

  @doc """
  Parses the passed in data, assuming it is in Procfile format.
  """
  @spec parse(String.t) :: [Command.t]
  def parse(data) do
    data
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn x -> x == "" end)
    |> Enum.map(&parse_line/1)
  end

  @spec parse_line(String.t) :: Command.t
  defp parse_line(line) do
    [name, command] = String.split(line, ":", parts: 2)
    %Jefe.Command{
      name: String.trim(name),
      cmd: String.trim(command)
    }
  end
end
