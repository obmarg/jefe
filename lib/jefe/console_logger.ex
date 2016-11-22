defmodule Jefe.ConsoleLogger do
  @moduledoc """
  Responsbile for logging the output of all commands to the console.
  """
  use GenServer
  require Logger

  alias Jefe.{OutputRouter, Procfile}

  @typep color_map :: %{String.t => (String.t -> String.t)}
  @typep state :: %{
    command_str_width: integer,
    color_map: color_map,
    buffers: %{String.t => String.t}
  }

  # Flush output to console every 200ms
  @flush_period 200

  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(nil) do
    commands = Procfile.read

    max_length = case commands do
      [] -> 0
      commands ->
        Enum.max(for command <- commands, do: String.length(command.name))
    end

    OutputRouter.subscribe

    setup_flush_timer

    {:ok,
     %{settings: Application.get_env(:jefe, :console_output) |> Enum.into(%{}),
       command_str_width: max_length,
       color_map: color_map(commands),
       buffers: %{}}}
  end

  def handle_info({:output, command_name, {_type, data}}, state) do
    {:noreply,
     update_in(state[:buffers][command_name], fn
       (nil) -> data
       (old_data) -> old_data <> data
     end)}
  end

  def handle_info(:flush, state) do
    Enum.each(state.buffers, fn {command_name, data} ->
      String.splitter(data, "\n")
      |> Enum.map(
        &format_line(command_name, state, &1)
      )
      |> Enum.each(&IO.puts/1)
    end)
    setup_flush_timer
    {:noreply, %{state | buffers: %{}}}
  end

  def handle_info(unknown, _state) do
    Logger.warn "Unknown message received in ConsoleLogger: #{inspect unknown}"
  end

  @spec color_map([Jefe.Command.t]) :: color_map
  defp color_map(commands) do
    color_fns = Stream.cycle([
      &IO.ANSI.green/0,
      &IO.ANSI.magenta/0,
      &IO.ANSI.cyan/0,
      &IO.ANSI.yellow/0,
      &IO.ANSI.blue/0,
      &IO.ANSI.red/0,
    ])
    for {command, color} <- Enum.zip(commands, color_fns), into: %{} do
      {command.name, fn (data) ->
        color.() <> data <> IO.ANSI.reset()
      end}
    end
  end

  @spec format_line(String.t, state, String.t) :: String.t
  defp format_line(command_name, state, line) do
    color_fn = state.color_map[command_name] || fn x -> x end
    time_str = if state.settings.clock do
      Timex.format!(Timex.now, "%T", :strftime) <> " "
    end
    command_name = String.pad_trailing(command_name, state.command_str_width)
    color_fn.("#{time_str || ""}#{command_name} | ") <> line
  end

  defp setup_flush_timer() do
    :erlang.send_after(@flush_period, self, :flush)
  end
end
