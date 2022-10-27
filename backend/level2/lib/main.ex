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

  def is_saturday?(date), do: 6 == Date.day_of_week(date)

  def is_sunday?(date), do: 7 == Date.day_of_week(date)

  def postpon(
        expected_delivery_date,
        0,
        saturday_deliveries
      ) do
    cond do
      is_saturday?(expected_delivery_date) && !saturday_deliveries ->
        postpon(
          Date.add(expected_delivery_date, 1),
          0,
          saturday_deliveries
        )

      is_sunday?(expected_delivery_date) ->
        postpon(
          Date.add(expected_delivery_date, 1),
          0,
          saturday_deliveries
        )

      true ->
        expected_delivery_date
    end
  end

  def postpon(
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

    postpon(
      Date.add(expected_delivery_date, 1),
      delivery_promise,
      saturday_deliveries
    )
  end

  def expected_delivery_date(package, carrier_data) do
    delivery_promise = get_in(carrier_data, [package.carrier, :delivery_promise])
    saturday_deliveries = get_in(carrier_data, [package.carrier, :saturday_deliveries])

    package.shipping_date
    |> Date.from_iso8601!()
    |> Date.add(1)
    |> postpon(delivery_promise, saturday_deliveries)
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
