import Config
config :logger, backends: [:console, Bluetooth.HCIDump.Logger]
