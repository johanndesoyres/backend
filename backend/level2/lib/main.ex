defmodule Main do
  @doc """
  Parser for the input json file.

  ## Examples

      iex> Main.parser("data/input.json")
      %{
        "carriers" => [
          %{"code" => "colissimo", "delivery_promise" => 3},
          %{"code" => "ups", "delivery_promise" => 2}
        ],
        "packages" => [
          %{"carrier" => "colissimo", "id" => 1, "shipping_date" => "2018-05-01"},
          %{"carrier" => "ups", "id" => 2, "shipping_date" => "2018-05-14"},
          %{"carrier" => "colissimo", "id" => 3, "shipping_date" => "2018-06-10"}
        ]
      }
  """
  def read_file(input_name) do
    input_name
    |> File.read!()
    |> Poison.decode(keys: :atoms)
  end

  def write_file(content, output_name) do
    :ok = File.write(output_name, Poison.encode!(content), [:binary])
  end

  def is_monday?(date) do
    1 == Date.day_of_week(date)
  end

  def is_saturday?(date) do
    6 == Date.day_of_week(date)
  end

  def postpon_for_monday(shipping_date, expected_delivery_date, range_size) do
    Date.range(shipping_date, expected_delivery_date)
    |> Enum.take(range_size)
    |> Enum.reduce(0, fn date, acc ->
      if is_monday?(date), do: acc + 1, else: acc
    end)
  end

  def postpon_for_saturday(
        _shipping_date,
        _expected_delivery_date,
        _range_size,
        true
      ) do
    0
  end

  def postpon_for_saturday(
        shipping_date,
        expected_delivery_date,
        range_size,
        _saturday_deliveries
      ) do
    Date.range(shipping_date, expected_delivery_date)
    |> Enum.take(range_size)
    |> Enum.reduce(0, fn date, acc ->
      if is_saturday?(date), do: acc + 1, else: acc
    end)
  end

  def expected_delivery_date(package, carrier_data) do
    delivery_promise = get_in(carrier_data, [package.carrier, :delivery_promise])
    saturday_deliveries = get_in(carrier_data, [package.carrier, :saturday_deliveries])
    shipping_date = Date.from_iso8601!(package.shipping_date)

    expected_delivery_date =
      shipping_date
      |> Date.add(delivery_promise + 1)

    range_size = Date.diff(expected_delivery_date, shipping_date)

    expected_delivery_date
    |> Date.add(postpon_for_monday(shipping_date, expected_delivery_date, range_size))
    |> Date.add(
      postpon_for_saturday(
        shipping_date,
        expected_delivery_date,
        range_size,
        saturday_deliveries
      )
    )
    |> Date.to_string()
  end

  def compute_expected_delivery_dates do
    {:ok, content} = read_file("data/input.json")

    carrier_data =
      content[:carriers]
      |> Enum.reduce(%{}, fn carrier, acc ->
        Map.merge(
          %{
            carrier[:code] => %{
              delivery_promise: carrier[:delivery_promise],
              saturday_deliveries: carrier[:saturday_deliveries]
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
            expected_delivery: expected_delivery_date(package, carrier_data)
          }
          | acc
        ]
      end)

    :ok = write_file(%{deliveries: expected_delivery_dates}, "data/output.json")
  end
end
