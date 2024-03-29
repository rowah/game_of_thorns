defmodule IslandsEngine.Island do
  @moduledoc """
  This is the Island module.
  """
  alias IslandsEngine.{Coordinate, Island}

  @enforce_keys [:coordinates, :hit_coordinates]
  defstruct [:coordinates, :hit_coordinates]

  @doc """
  Gives a game board.

  Returns `%{:ok, %IslandEngine.Island{}}`.

  ## Examples

      iex> IslandEngine.Island.new()
      %{}

  """
  def new(type, %Coordinate{} = upper_left) do
    with [_ | _] = offsets <- offset(type),
         %MapSet{} = coordinates <- add_coordinates(offsets, upper_left) do
      {:ok, %Island{coordinates: coordinates, hit_coordinates: MapSet.new()}}
    else
      error -> error
    end
  end

  defp offset(:square), do: [{0, 0}, {0, 1}, {1, 0}, {1, 1}]
  defp offset(:atoll), do: [{0, 0}, {0, 1}, {1, 1}, {2, 0}, {2, 1}]
  defp offset(:dot), do: [{0, 0}]
  defp offset(:l_shape), do: [{0, 0}, {1, 0}, {2, 0}, {2, 1}]
  defp offset(:s_shape), do: [{0, 1}, {0, 2}, {1, 0}, {1, 1}]
  defp offset(_), do: [:error, :invalid_island_type]

  # enumerates over the list of offsets, create a new coordinate for each one, and put them all into the same set. It takes an enumerable, a starting value for an accumulator, and a function to apply to each enumerated value. For us, those three arguments will be the list of offsets, a new MapSet, and a new function we’ll get to in a minute. must return one of two tagged tuples: either {:cont, some_value} to continue the enumeration, or {:halt, some_value} to end it
  defp add_coordinates(offsets, upper_left) do
    Enum.reduce_while(offsets, MapSet.new(), fn offset, acc ->
      add_coordinate(acc, upper_left, offset)
    end)
  end

  defp add_coordinate(coordinates, %Coordinate{row: row, col: col}, {row_offset, col_offset}) do
    case Coordinate.new(row + row_offset, col + col_offset) do
      {:ok, coordinate} ->
        {:cont, MapSet.put(coordinates, coordinate)}

      {:error, :invalid_coordinate} ->
        {:halt, {:error, :invalid_coordinate}}
    end
  end

  def overlaps?(existing_island, new_island),
    do: not MapSet.disjoint?(existing_island.coordinates, new_island.coordinates)

  def guess(island, coordinate) do
    case MapSet.member?(island.coordinates, coordinate) do
      true ->
        hit_coordinates = MapSet.put(island.hit_coordinates, coordinate)
        {:hit, %{island | hit_coordinates: hit_coordinates}}

      false ->
        :miss
    end
  end

  def forested?(island), do: MapSet.equal?(island.coordinates, island.hit_coordinates)

  def types(), do: [:atoll, :dot, :l_shape, :s_shape, :square]
end
