defmodule Jefe.Command do
  @moduledoc """
  Struct describing a command jefe can run.
  """
  defstruct [:name, :cmd]

  @type t :: %__MODULE__{
    name: String.t,
    cmd: String.t
  }
end
