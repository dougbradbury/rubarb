module Dkbrpc
  module Default
    INSECURE_METHODS = [:==, :===, :=~, :__drbref, :__drburi, :__id__, :__send__, :_dump,
    :class, :clone, :display, :dup, :enum_for, :eql?, :equal?, :extend, :freeze,
    :frozen?, :hash, :id, :inspect, :instance_eval, :instance_exec, :instance_of?, :instance_variable_defined?,
    :instance_variable_get, :instance_variable_set, :is_a?, :kind_of?, :method, :method_missing,
    :methods, :nil?, :object_id, :pretty_print, :pretty_print_cycle, :private_methods,
    :protected_methods, :public_methods, :respond_to?, :send, :singleton_methods,
    :taint, :tainted?, :tap, :to_enum, :type, :untaint,
    :add_options, :args_and_options, :as_null_object, :com, :config, :config=, :context, :dclone, :debugger,
    :handle_different_imports, :hash, :include_class, :java, :java_kind_of?, :javax, :log, :null_object?, :org,
    :received_message?, :taguri, :taguri=, :taint, :tainted?, :tap, :timeout, :to_a, :to_channel, :to_inputstream,
    :to_outputstream, :to_s, :to_yaml, :to_yaml_properties, :to_yaml_style]
  end
end
