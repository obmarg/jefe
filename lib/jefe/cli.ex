defmodule Jefe.CLI do
  @moduledoc """
  Implements an escript entry point.

  Jefe is really intended to be used as a command line utility, so an escript
  makes a lot more sense than distributing a full OTP release.

  One complication with an escript is we don't have access to priv directories
  from within an escript, so we manually download rebar and erlexec, then use
  rebar to build exec-port.
  """

  # We're building an escript so don't have access to priv/*
  # So, load in the build_exec_port script at compile time.
  @build_exec_port File.read! "priv/build_exec_port.sh"
  @external_resource "priv/build_exec_port.sh"

  def main(args) do
    get_exec_port()

    Application.put_env(:erlexec, :portexe, String.to_charlist(exec_port_exe))

    {:ok, _} = Application.ensure_all_started(:jefe)

    :timer.sleep(:infinity)
  end

  defp get_exec_port() do
    unless File.exists?(exec_port_exe) do
      temp_dir = temp_dir
      File.mkdir!(temp_dir)

      shell_path = Path.join(temp_dir, "build_exec_port.sh")

      IO.puts "Writing shell script to #{shell_path}"
      File.write!(shell_path, @build_exec_port, [:write])
      File.chmod!(shell_path, 0o500)

      {_, 0} = System.cmd(
        shell_path,
        [Application.get_env(:jefe, :rebar_version),
         Application.get_env(:jefe, :erlexec_version)],
        cd: temp_dir,
        into: IO.stream(:stdio, :line)
      )

      # Find the executable we created and copy it to the right location...
      executable_file = Path.join([
        temp_dir, "erlexec", "priv", arch_dir, "exec-port"
      ])
      unless File.exists?(executable_file) do
        raise RuntimeError, "build_exec_port.sh did not output exec-port in expected place"
      end

      File.mkdir_p!(exec_port_dir)
      File.cp!(executable_file, exec_port_exe)
      File.chmod!(exec_port_exe, 0o700)
    end
  end

  defp exec_port_dir, do: Path.expand("~/.jefe/builds/#{arch_dir}")
  defp exec_port_exe, do: "#{exec_port_dir}/exec-port"

  # arch_dir gets the architecture exec-port will be built for.
  # This mirrors the logic for determining Mach in erlexec/rebar.config.script
  @spec arch_dir :: String.t
  defp arch_dir do
    arch = :system_architecture |> :erlang.system_info() |> List.to_string
    case String.contains?(arch, "linux") do
      false -> arch
      true ->
        case :string.words(arch, '-') do
          4 -> arch
          _ -> arch <> "-gnu"
        end
    end
  end

  @spec temp_dir :: String.t
  defp temp_dir do
    cond do
      File.exists?("/tmp") -> "/tmp/"
      File.exists?("/var/tmp") -> "/var/tmp"
      tmp = System.get_env("TEMP") -> tmp
      true -> raise RuntimeError, "Could not find temporary directory"
    end <> random_postfix
  end

  @spec random_postfix :: String.t
  defp random_postfix do
    1..10
    |> Enum.map(fn (_) -> Enum.random('abcdefghijklmnopqrstuvwxyz') end)
    |> Enum.join
  end
end
