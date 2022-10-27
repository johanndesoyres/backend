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

  def expected_delivery_date(package, delivery_promises) do
    package.shipping_date
    |> Date.from_iso8601!()
    |> Date.add(Map.get(delivery_promises, package.carrier) + 1)
    |> Date.to_string()
  end

  def compute_expected_delivery_dates do
    {:ok, content} = read_file("data/input.json")

    delivery_promises =
      content[:carriers]
      |> Enum.reduce(%{}, fn carrier, acc ->
        Map.merge(%{carrier[:code] => carrier[:delivery_promise]}, acc)
      end)

    expected_delivery_dates =
      content[:packages]
      |> Enum.reduce([], fn package, acc ->
        [
          %{
            package_id: package.id,
            expected_delivery: expected_delivery_date(package, delivery_promises)
          }
          | acc
        ]
      end)

    :ok = write_file(%{deliveries: expected_delivery_dates}, "data/output.json")
  end
end
