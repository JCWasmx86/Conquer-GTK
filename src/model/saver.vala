/* saver.vala
 *
 * Copyright 2022 JCWasmx86 <JCWasmx86@t-online.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
public interface Conquer.Saver : GLib.Object {
    public abstract string name { get; protected set; }
    public abstract bool name_is_available (string name);
    public abstract void save (string name, string uuid, GLib.Bytes data);
}

public interface Conquer.Serializer : GLib.Object {
    public abstract GLib.Bytes serialize (Conquer.GameState state);
    public abstract bool supports_uuid (string uuid);
}

public interface Conquer.Deserializer : GLib.Object {
    public abstract Conquer.GameState deserialize (GLib.Bytes state, Conquer.Strategy[] strategies);
    public abstract bool supports_uuid (string uuid);
}

public interface Conquer.SaveLoader : GLib.Object {
    public abstract Conquer.SavedGame[] enumerate ();
}

public interface Conquer.SavedGame : GLib.Object {
    public abstract string name { get; set; }
    public abstract DateTime time { get; set; }
    public abstract string guid { get; set; }
    public abstract GameState load(Conquer.Deserializer[] deserializers, Conquer.Strategy[] strategies);
}
