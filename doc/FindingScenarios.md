## Find scenarios
The template files for scenarios can be found by `ScenarioLoader`s. The class `ScenarioLoader` requires
implementing a method called `enumerate`, that returns all scenarios that can be found.

This way it is possible to query different storage locations be it local or remote.
