defmodule BlueHeron.GATT.Characteristic do
  defstruct [:id, :type, :properties, :handle, :value_handle]

  # id is required, can be any term, but must be unique within the services() function
  # type is required, must be either 16 or 128 bit UUID
  # properties is required, must be an integer between 0 and 255
  # handle and value_handle should not be specified by the user
  def new(args) do
    args = Map.take(args, [:id, :type, :properties])
    struct!(__MODULE__, args)
  end
end
