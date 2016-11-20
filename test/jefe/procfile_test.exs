defmodule JefeProcfileTest do
  use ExUnit.Case

  alias Jefe.{Command, Procfile}

  test "can parse procfiles" do
    assert Procfile.parse("""
    web: http $PORT
    task: liege worker:1234
    """) == [
      %Command{name: "web", cmd: "http $PORT"},
      %Command{name: "task", cmd: "liege worker:1234"}
    ]
  end
end
