## Configuration.
During loading of all plugins, in `peas_register_types`, a `Conquer.Configuration` should be registered.
It will return a list of all config items for the plugin.

If the configuration is updated, you a message is emitted, called `Conquer.ConfigurationUpdatedMessage` and is stored somewhere
in an undefined manner.

