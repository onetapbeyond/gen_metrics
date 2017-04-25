defmodule GenMetrics.Utils.Runtime do
    @moduledoc false

    @doc """
    Verify modules are compiled and loaded.

    Returns an empty list if all modules are 
    successfully compiled and loaded.

    Returns a non-empty list of error messages describing
    each module that fails to compile or load.
    """
    @spec require_modules([module]) :: [String.t]
    def require_modules(module_list) do
        module_list
        |> Enum.uniq
        |> Enum.reduce([], fn(module, acc) ->
            try do
                Code.eval_string("require #{inspect module}")
                acc
            rescue
                _ -> ["Module #{inspect module} not loaded and could not be found." | acc]
            end
        end)
    end

    @doc """
    Verify modules implement a required behaviour.

    Returns an empty list if all modules successfully
    implement the required behaviour.

    Returns a non-empty list of error messages describing
    each module that fails to implement the required behaviour.
    """
    @spec require_behaviour([module], module) :: [String.t]
    def require_behaviour(module_list, behaviour) do
      module_list
      |> Enum.uniq
      |> Enum.reduce([], fn(module, acc) ->
        try do
          attrs = apply(module, :__info__, [:attributes])
          behaviours = get_in(attrs, [:behaviour])
          if behaviour in behaviours do
            acc
          else
            ["Module #{inspect module} does not implement #{inspect behaviour}." | acc]
          end
        rescue
          _ -> ["Module #{inspect module} does not implement #{inspect behaviour}." | acc]
        end
      end)
    end

    def safe_div(0, _), do: 0
    def safe_div(num, d), do: div(num, d)

    def micro_to_milli(0), do: 0
    def micro_to_milli(milli), do: safe_div(milli, 1000)

    def nano_to_micro(0), do: 0
    def nano_to_micro(nano), do: safe_div(nano, 1000)

    def nano_to_milli(0), do: 0
    def nano_to_milli(nano), do: safe_div(nano, 1_000_000)

end
