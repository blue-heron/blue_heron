defmodule BlueHeron.GATT.Service do
  @type t() :: map()

  defstruct [
    :id,
    :primary?,
    :type,
    :included_services,
    :characteristics,
    :handle,
    :end_group_handle
  ]

  # id is required, can be any term, but must be unique within the services() function
  # primary? defaults to true, set it to false if it should only show up as an included service
  # type is required, must be either 16 or 128 bit UUID
  # included_services is a list of service ID's to be included in the definition of this service
  # characteristics is a list of characteristics
  def new(args) do
    args =
      Map.put_new(args, :primary?, true)
      |> Map.take([:id, :primary?, :type, :included_services, :characteristics])

    struct!(__MODULE__, args)
  end
end
