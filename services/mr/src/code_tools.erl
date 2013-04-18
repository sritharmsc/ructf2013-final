-module(code_tools).
-export([parse_data/1, compile/2, check_security/1]).

parse_data(Data) when is_binary(Data) ->
    parse_data(binary_to_list(Data));
parse_data(Data) when is_list(Data) ->
    {ok, Tokens, _} = erl_scan:string(Data),
    erl_parse:parse_term(Tokens).

compile(ModuleName, ErlangCode) when is_binary(ErlangCode) ->
    compile(ModuleName, binary_to_list(ErlangCode));
compile(ModuleName, ErlangCode) ->
    ModuleHeader = "-module(" ++ ModuleName ++ ").",
    ExportHeader = "-export([map/3, reduce/3]).",
    ModuleCode = string:join([ModuleHeader, ExportHeader, ErlangCode], "\n"),
    {ok, Tokens, _} = erl_scan:string(ModuleCode),
    FormTokens = split_forms(Tokens),
    Forms  = lists:map(fun(T) -> {ok, Form} = erl_parse:parse_form(T), Form end, FormTokens),
    {ok, _, Beam} = compile:forms(Forms, [debug_info]),
    {ok, Beam}.

split_forms(Tokens) ->
    split_forms(Tokens, [], []). 
split_forms([], [], Acc) ->
    lists:reverse(Acc);
split_forms([{dot, N} | Tokens], CurrentToken, Acc) ->
    Token = lists:reverse([{dot, N} | CurrentToken]),
    split_forms(Tokens, [], [Token | Acc]);
split_forms([Token | Tokens], CurrentToken, Acc) ->
    split_forms(Tokens, [Token | CurrentToken], Acc).

check_security(ModuleName) when is_atom(ModuleName) ->
    check_security(atom_to_list(ModuleName));
check_security(ModuleName) ->
    {ok, {_, [{imports, Imports}]}} = beam_lib:chunks("priv/code/" ++ ModuleName, [imports]),
    BlackList = blacklist(),
    check_security(Imports, BlackList).

check_security([], _) ->
    ok;
check_security([Import | Tail], BlackList) ->
    case match(Import, BlackList) of
        false -> check_security(Tail, BlackList);
        true  -> throw(secfail)
    end.

match(_, []) ->
    false;
match({M, F, _}, [{M, F} | _]) ->
    true;
match({M, _, _}, [{M, "_"} | _]) ->
    true;
match(I, [_ | T]) ->
    match(I, T).

blacklist() ->
    [{io, "_"},
     {erl_distribution, "_"},
     {edlin, "_"},
     {ibrowse, "_"},
     {zlib, "_"},
     {error_handler, "_"},
     {crypto_server, "_"},
     {erl_ddll, "_"},
     {filename, "_"},
     {yaws_generated, "_"},
     {yaws, "_"},
     {unicode, "_"},
     {inet_db, "_"},
     {yaws_davlock, "_"},
     {yaws_sendfile, "_"},
     {inet, "_"},
     {timer, "_"},
     {group, "_"},
     {gen_tcp, "_"},
     {crypto_sup, "_"},
     {gen, "_"},
     {erl_scan, "_"},
     {kernel, "_"},
     {erl_eval, "_"},
     {prim_file, "_"},
     {ets, "_"},
     {inets, "_"},
     {inet_udp, "_"},
     {crypto, "_"},
     {io_lib_pretty, "_"},
     {yaws_log, "_"},
     {code, "_"},
     {ram_file, "_"},
     {packages, "_"},
     {yaws_sup_restarts, "_"},
     {ftp_sup, "_"},
     {inet_tcp, "_"},
     {binary, "_"},
     {gen_event, "_"},
     {heart, "_"},
     {io_lib_format, "_"},
     {erl_lint, "_"},
     {filelib, "_"},
     {kernel_config, "_"},
     {inet_gethost_native, "_"},
     {gen_server, "_"},
     {proc_lib, "_"},
     {httpc_manager, "_"},
     {inets_sup, "_"},
     {yaws_app, "_"},
     {application, "_"},
     {global, "_"},
     {otp_internal, "_"},
     {erl_internal, "_"},
     {yaws_trace, "_"},
     {code_server, "_"},
     {file_server, "_"},
     {beam_lib, "_"},
     {prim_zip, "_"},
     {httpc_sup, "_"},
     {httpd_sup, "_"},
     {crypto_app, "_"},
     {yaws_config, "_"},
     {httpc_cookie, "_"},
     {os, "_"},
     {rpc, "_"},
     {c, "_"},
     {httpc, "_"},
     {file_io_server, "_"},
     {httpc_profile_sup, "_"},
     {tftp_sup, "_"},
     {yaws_ctl, "_"},
     {inet_config, "_"},
     {yaws_debug, "_"},
     {user_drv, "_"},
     {inet_parse, "_"},
     {prim_inet, "_"},
     {yaws_rss, "_"},
     {yaws_server, "_"},
     {yaws_logger, "_"},
     {yaws_ticker, "_"},
     {compile, "_"},
     {hipe_unified_loader, "_"},
     {error_logger, "_"},
     {standard_error, "_"},
     {global_group, "_"},
     {inets_app, "_"},
     {yaws_sup, "_"},
     {shell, "_"},
     {file, "_"},
     {inets_trace, "_"},
     {yaws_session_server, "_"},
     {net_kernel, "_"},
     {error_logger_tty_h, "_"},
     {error_logger_file_h, "_"},
     {supervisor_bridge, "_"},
     {application_master, "_"},
     {otp_ring0, "_"},
     {httpc_handler_sup, "_"},
     {yaws_log_file_h, "_"},
     {erl_parse, "_"},
     {init, "_"},
     {edlin_expand, "_"},
     {sys, "_"},
     {erl_prim_loader, "_"},
     {supervisor, "_"},
     {application_controller, "_"},
     {user_sup, "_"},
     {erlang, trace_delivered},
     {erlang, decode_packet},
     {erlang, port_close},
     {erlang, dsend},
     {erlang, processes},
     {erlang, finish_after_on_load},
     {erlang, apply},
     {erlang, system_info},
     {erlang, seq_trace},
     {erlang, match_spec_test},
     {erlang, group_leader},
     {erlang, port_command},
     {erlang, gather_sched_wall_time_result},
     {erlang, port_connect},
     {erlang, send},
     {erlang, iolist_to_binary},
     {erlang, trace_pattern},
     {erlang, binary_to_term},
     {erlang, dmonitor_p},
     {erlang, disconnect_node},
     {erlang, load_nif},
     {erlang, dmonitor_node},
     {erlang, nif_error},
     {erlang, register},
     {erlang, trace},
     {erlang, put},
     {erlang, unregister},
     {erlang, port_control},
     {erlang, bump_reductions},
     {erlang, suspend_process},
     {erlang, port_get_data},
     {erlang, delay_trap},
     {erlang, await_proc_exit},
     {erlang, binary_to_atom},
     {erlang, spawn_monitor},
     {erlang, posixtime_to_universaltime},
     {erlang, memory},
     {erlang, split_binary},
     {erlang, open_port},
     {erlang, purge_module},
     {erlang, erase},
     {erlang, garbage_collect_message_area},
     {erlang, setnode},
     {erlang, alloc_info},
     {erlang, read_timer},
     {erlang, list_to_bitstring},
     {erlang, port_info},
     {erlang, dt_restore_tag},
     {erlang, external_size},
     {erlang, unlink},
     {erlang, dgroup_leader},
     {erlang, append_element},
     {erlang, phash},
     {erlang, monitor},
     {erlang, get},
     {erlang, iolist_size},
     {erlang, dexit},
     {erlang, port_set_data},
     {erlang, seq_trace_info},
     {erlang, trunc},
     {erlang, await_sched_wall_time_modifications},
     {erlang, send_nosuspend},
     {erlang, send_after},
     {erlang, dt_append_vm_tag_data},
     {erlang, cancel_timer},
     {erlang, link},
     {erlang, resume_process},
     {erlang, list_to_atom},
     {erlang, fun_info},
     {erlang, tuple_size},
     {erlang, monitor_node},
     {erlang, process_flag},
     {erlang, raise},
     {erlang, trace_info},
     {erlang, make_ref},
     {erlang, binary_part},
     {erlang, subtract},
     {erlang, display},
     {erlang, display_nl},
     {erlang, spawn},
     {erlang, system_profile},
     {erlang, pre_loaded},
     {erlang, node},
     {erlang, garbage_collect},
     {erlang, get_stacktrace},
     {erlang, load_module},
     {erlang, dt_spread_tag},
     {erlang, alloc_sizes},
     {erlang, ports},
     {erlang, get_cookie},
     {erlang, nodes},
     {erlang, phash2},
     {erlang, check_old_code},
     {erlang, crasher},
     {erlang, call_on_load_function},
     {erlang, delete_module},
     {erlang, seq_trace_print},
     {erlang, dist_exit},
     {erlang, dt_put_tag},
     {erlang, demonitor},
     {erlang, adler32_combine},
     {erlang, loaded},
     {erlang, flush_monitor_message},
     {erlang, hibernate},
     {erlang, make_fun},
     {erlang, halt},
     {erlang, hash},
     {erlang, port_call},
     {erlang, dlink},
     {erlang, dt_get_tag},
     {erlang, set_cpu_topology},
     {erlang, registered},
     {erlang, dunlink},
     {erlang, system_flag},
     {erlang, start_timer},
     {erlang, format_cpu_topology},
     {erlang, set_cookie},
     {erlang, spawn_link},
     {erlang, spawn_opt},
     {erlang, dt_prepend_vm_tag_data},
     {erlang, system_monitor},
     {erlang, dt_get_tag_data}].
