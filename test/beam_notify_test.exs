defmodule BEAMNotifyTest do
  use ExUnit.Case

  defp beam_notify_child_spec(context) do
    us = self()
    {BEAMNotify, name: context.test, dispatcher: &send(us, {&1, &2})}
  end

  test "directly sending a message", context do
    pid = start_supervised!(beam_notify_child_spec(context))

    env = BEAMNotify.env(pid)
    {"", 0} = System.cmd(env["BEAM_NOTIFY"], ["hello", "from", "a", "c", "program"], env: env)

    assert_receive {["hello", "from", "a", "c", "program"], %{}}
  end

  test "sending a message via a script", context do
    pid = start_supervised!(beam_notify_child_spec(context))

    {"This is simple.sh\n", 0} =
      System.cmd("/bin/sh", ["test/support/simple.sh"], env: BEAMNotify.env(pid))

    assert_receive {["Hello", "world"], %{}}
  end

  test "capturing environment variables", context do
    pid = start_supervised!(beam_notify_child_spec(context))

    {"This is set_env.sh\n", 0} =
      System.cmd("/bin/sh", ["test/support/set_env.sh"], env: BEAMNotify.env(pid))

    assert_receive {[], %{"TEST_ENV_VAR" => "42"}}
  end
end
