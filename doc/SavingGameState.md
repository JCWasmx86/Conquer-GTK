## Saving Gamestate
Saving gamestate is a two step process.

### Step 1 - Serialize the state to bytes
The `Conquer.Serializer` requires you to serialize the state to `GLib.Bytes`, as this is the most abstract
representation possible. It should contain everything required to deserialize.

### Step 2 - Save the data
The `Conquer.Saver` will simply save the bytes obtained from Step 1. This allows multiple storage locations
like on the local filesystem, in a database or somewhere remote.
