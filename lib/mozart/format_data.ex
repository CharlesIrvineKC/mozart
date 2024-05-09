{:error,
 {:undef,
  [
    {Mozart.ProcessEngine, :start_link,
     [{"73ca3321-d1fc-4f69-9d05-404de0fae1dc", :user_task_process_model, %{value: 0}, nil}], []
     },
    {DynamicSupervisor, :start_child, 3, [file: ~c"lib/dynamic_supervisor.ex", line: 795]},
    {DynamicSupervisor, :handle_start_child, 2, [file: ~c"lib/dynamic_supervisor.ex", line: 781]},
    {:gen_server, :try_handle_call, 4, [file: ~c"gen_server.erl", line: 1131]},
    {:gen_server, :handle_msg, 6, [file: ~c"gen_server.erl", line: 1160]},
    {:proc_lib, :init_p_do_apply, 3, [file: ~c"proc_lib.erl", line: 241]}
  ]}}
