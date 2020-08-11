import Config

config :logger,
  backends: [:console, Bluetooth.HCIDump.Logger],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]
