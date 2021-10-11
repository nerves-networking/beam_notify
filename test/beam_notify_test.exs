defmodule BEAMNotifyTest do
  use ExUnit.Case

  defp beam_notify_child_spec(context, extra_options \\ []) do
    us = self()
    base_options = [name: context.test, dispatcher: &send(us, {&1, &2})]
    {BEAMNotify, Keyword.merge(base_options, extra_options)}
  end

  test "directly sending a message", context do
    pid = start_supervised!(beam_notify_child_spec(context))

    env = BEAMNotify.env(pid)
    {"", 0} = System.cmd(env["BEAM_NOTIFY"], ["hello", "from", "a", "c", "program"], env: env)

    empty_map = %{}
    assert_receive {["hello", "from", "a", "c", "program"], ^empty_map}
  end

  test "nameless use" do
    us = self()
    pid = start_supervised!({BEAMNotify, dispatcher: &send(us, {&1, &2})})

    env = BEAMNotify.env(pid)
    {"", 0} = System.cmd(env["BEAM_NOTIFY"], ["hello", "nameless"], env: env)

    assert_receive {["hello", "nameless"], %{}}
  end

  test "explicit socket path" do
    us = self()
    pid = start_supervised!({BEAMNotify, path: "test_socket", dispatcher: &send(us, {&1, &2})})

    env = BEAMNotify.env(pid)
    {"", 0} = System.cmd(env["BEAM_NOTIFY"], ["hello", "explicit", "path"], env: env)

    assert_receive {["hello", "explicit", "path"], %{}}
  end

  test "explicit socket permissions" do
    # Unusual mode
    mode = 0o711
    _ = start_supervised!({BEAMNotify, path: "test_socket", mode: mode})

    assert mode == Bitwise.band(File.stat!("test_socket").mode(), 0o777)
  end

  test "sending a message via a script", context do
    pid = start_supervised!(beam_notify_child_spec(context))

    {"This is simple.sh\n", 0} =
      System.cmd("/bin/sh", ["test/support/simple.sh"], env: BEAMNotify.env(pid))

    assert_receive {["Hello", "world"], %{}}
  end

  test "capturing environment variables", context do
    pid = start_supervised!(beam_notify_child_spec(context, report_env: true))

    {"This is set_env.sh\n", 0} =
      System.cmd("/bin/sh", ["test/support/set_env.sh"], env: BEAMNotify.env(pid))

    assert_receive {[], %{"TEST_ENV_VAR" => "42"}}
  end

  test "bin_path/0 location matches environment" do
    env = BEAMNotify.env(name: "test_name")
    bin_path = BEAMNotify.bin_path()

    assert bin_path == env["BEAM_NOTIFY"]
  end

  test "sending a message via commandline args", context do
    pid = start_supervised!(beam_notify_child_spec(context))
    script = "#{BEAMNotify.bin_path()} #{BEAMNotify.env(pid)["BEAM_NOTIFY_OPTIONS"]} -- hello"

    # BEAM_NOTIFY_OPTIONS not set
    {"", 0} = System.cmd("/bin/sh", ["-c", script])
    assert_receive {["hello"], %{}}

    # BEAM_NOTIFY_OPTIONS set to an empty string (easy mistake when trying to unset a variable)
    {"", 0} = System.cmd("/bin/sh", ["-c", script], env: %{"BEAM_NOTIFY_OPTIONS" => ""})

    assert_receive {["hello"], %{}}

    # BEAM_NOTIFY_OPTIONS set to a string with spaces
    {"", 0} = System.cmd("/bin/sh", ["-c", script], env: %{"BEAM_NOTIFY_OPTIONS" => "   "})

    assert_receive {["hello"], %{}}
  end
end
