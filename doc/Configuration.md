## Configuration.
During loading of all plugins, in `peas_register_types`, a `Conquer.Configuration` should be registered.
It will return a list of all config items for the plugin.

If the configuration is updated, a message called `Conquer.ConfigurationUpdatedMessage` is emitted and the config is stored somewhere
in an undefined manner.

