defmodule Main do
  @doc """
  Reader for the input json file.

  ## Examples

      iex> Main.read_file("data/input.json")
     {:ok,
        %{
        carriers: [
          %{code: "colissimo", delivery_promise: 3},
          %{code: "ups", delivery_promise: 2}
        ],
        packages: [
          %{carrier: "colissimo", id: 1, shipping_date: "2018-05-01"},
          %{carrier: "ups", id: 2, shipping_date: "2018-05-14"},
          %{carrier: "colissimo", id: 3, shipping_date: "2018-06-10"}
        ]
      }}
  """
  def read_file(input_name) do
    input_name
    |> File.read!()
    |> Poison.decode(keys: :atoms)
  end

  @doc """
  Writer for the output file.

  ## Examples

      iex> Main.write_file("data/input.json")
     :ok
  """
  def write_file(content, output_name) do
    :ok = File.write(output_name, Poison.encode!(content), [:binary])
  end

  @doc """
  Checked if the provided date is on saturday.

  ## Examples

      iex> Main.is_saturday?(~D[2018-05-01])
      false
  """
  def is_saturday?(date), do: 6 == Date.day_of_week(date)

  @doc """
  Checked if the provided date is on sunday.

  ## Examples

      iex> Main.is_sunday?(~D[2018-05-01])
      false
  """
  def is_sunday?(date), do: 7 == Date.day_of_week(date)

  @doc """
  Get the distance between two country.

  ## Examples

      iex> Main.country_distance(%{"FR": { "US": 6000, "DK": 1000, "JP": 9500 },...}, "FR", "JP")
      9500
  """
  def country_distance(distances, origin_country, destination_country) do
    get_in(distances, [String.to_atom(origin_country), String.to_atom(destination_country)])
  end

  @doc """
  Compute the oversea delay (in days) based on the country distance and the oversea delay threshold.

  ## Examples

      iex> Main.oversea_delay(%{"FR": { "US": 6000, "DK": 1000, "JP": 9500 },...}, "FR", "JP", 3000)
      3
  """
  def oversea_delay(distances, origin_country, destination_country, oversea_delay_threshold) do
    distances
    |> country_distance(origin_country, destination_country)
    |> div(oversea_delay_threshold)
  end

  def postpone(
        expected_delivery_date,
        0,
        saturday_deliveries
      ) do
    cond do
      is_saturday?(expected_delivery_date) && !saturday_deliveries ->
        postpone(
          Date.add(expected_delivery_date, 1),
          0,
          saturday_deliveries
        )

      is_sunday?(expected_delivery_date) ->
        postpone(
          Date.add(expected_delivery_date, 1),
          0,
          saturday_deliveries
        )

      true ->
        expected_delivery_date
    end
  end

  @doc """
  Postpone the delivery date if needed (accordingly to the rules provided in the readme.
  This function is recursive. The delivery promise is the number of calls.
  The logic here is to increment the delivery date during each call of the function.
  If the current delivery date falls on a Saturday or Sunday then an additional recursive
  call is made if necessary. We return the final delivery date when the number of calls is 0 and
  the current date is neither Saturday nor Sunday.
  """
  def postpone(
        expected_delivery_date,
        delivery_promise,
        saturday_deliveries
      ) do
    delivery_promise =
      cond do
        is_saturday?(expected_delivery_date) && !saturday_deliveries ->
          delivery_promise

        is_sunday?(expected_delivery_date) ->
          delivery_promise

        true ->
          delivery_promise - 1
      end

    postpone(
      Date.add(expected_delivery_date, 1),
      delivery_promise,
      saturday_deliveries
    )
  end

  @doc """
  Compute the expected delivery date for a specific package.
  """
  def expected_delivery_date(package, carrier_data, distances) do
    delivery_promise = get_in(carrier_data, [package.carrier, :delivery_promise])
    saturday_deliveries = get_in(carrier_data, [package.carrier, :saturday_deliveries])
    oversea_delay_threshold = get_in(carrier_data, [package.carrier, :oversea_delay_threshold])

    oversea_delay =
      oversea_delay(
        distances,
        package.origin_country,
        package.destination_country,
        oversea_delay_threshold
      )

    package.shipping_date
    |> Date.from_iso8601!()
    |> Date.add(1)
    |> postpone(delivery_promise + oversea_delay, saturday_deliveries)
    |> Date.to_string()
  end

  @doc """
  Compute the expected delivery dates for all packages from the input json
  file and write the result in the output json file.
  """
  def compute_expected_delivery_dates do
    {:ok, content} = read_file("data/input.json")

    carrier_data =
      content[:carriers]
      |> Enum.reduce(%{}, fn carrier, acc ->
        Map.merge(
          %{
            carrier[:code] => %{
              delivery_promise: carrier[:delivery_promise],
              saturday_deliveries: carrier[:saturday_deliveries],
              oversea_delay_threshold: carrier[:oversea_delay_threshold]
            }
          },
          acc
        )
      end)

    expected_delivery_dates =
      content[:packages]
      |> Enum.reduce([], fn package, acc ->
        [
          %{
            package_id: package.id,
            expected_delivery:
              expected_delivery_date(package, carrier_data, content[:country_distance])
          }
          | acc
        ]
      end)
      |> Enum.reverse()

    :ok = write_file(%{deliveries: expected_delivery_dates}, "data/output.json")
  end
end
