defmodule GenMetrics.Utils.Math do
  @moduledoc false

  # For runtime performance reasons this library requires
  # the input data length to be provided, not calculated.

  def sum(data), do: Enum.sum data

  def sort(data), do: Enum.sort data

  def max([]), do: 0
  def max(data), do: Enum.max data

  def min([]), do: 0
  def min(data), do: Enum.min data

  def mean([], _), do: 0
  def mean(data, length), do: round(sum(data) / length)

  def variance([], _), do: 0
  def variance(data, length) do
    mean = mean(data, length)
    round(sum(Enum.map(data, &((mean - &1) * (mean - &1)))) / length)
  end

  def stdev([], _), do: 0
  def stdev(data, length) do
    round(:math.sqrt(variance(data, length)))
  end

  def range([]), do: 0
  def range(data) do
    sorted = sort(data)
    List.last(sorted) - List.first(sorted)
  end

end
