defmodule ConsoleLoggerTest do
  use ExUnit.Case

  alias Jefe.{ConsoleLogger, OutputRouter}

  test "ConsoleLogger outputs any data it is sent" do
    require Logger
    Logger.info "MY PID: #{inspect self}"
    {:ok, pid} = ConsoleLogger.start_link
    true = Process.group_leader(pid, self)

    msg = "Hello there my friend!\r\n"

    OutputRouter.stdout("test", msg)

    assert_receive {:io_request, _, _, {:put_chars, :unicode, msg1}}
    # Note: this is a bit hacky: we're expected to reply to this io_request
    # message, but we don't.
    # It does mean we can't easily receive more than one line though...
  end
end
