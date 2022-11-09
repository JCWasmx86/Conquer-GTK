/* config.vala
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
public interface Conquer.Configuration : GLib.Object {
    public abstract string name { get; set; }
    public abstract Conquer.ConfigurationItem[] config();
}

public abstract class Conquer.ConfigurationItem : GLib.Object {
    public string name { get; set; }
    public string description { get; set; }
}
public class Conquer.IntegerConfigurationItem : Conquer.ConfigurationItem {
    public int64 @value { get; set; }
    public int64 min { get; set; default = int64.MAX; }
    public int64 max { get; set; default = int64.MAX; }
}

public class Conquer.StringConfigurationItem : Conquer.ConfigurationItem {
    public string @value { get; set; }
}
public class Conquer.BoolConfigurationItem : Conquer.ConfigurationItem {
    public bool @value { get; set; }
}
