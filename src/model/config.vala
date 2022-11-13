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
    public abstract string id { get; set; }
    public abstract GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }
}

public abstract class Conquer.ConfigurationItem : GLib.Object {
    public string name { get; set; }
    public string id { get; set; }
    public string description { get; set; }
    public abstract void assign (Conquer.ConfigurationItem assign);
}
public class Conquer.IntegerConfigurationItem : Conquer.ConfigurationItem {
    public int64 @value { get; set; }
    public int64 min { get; set; default = int64.MAX; }
    public int64 max { get; set; default = int64.MAX; }

    public IntegerConfigurationItem (string name, string id, string description, int64 min, int64 max, int64 @default) {
        this.name = name;
        this.id = id;
        this.description = description;
        this.min = min;
        this.max = max;
        this.@value = @default;
    }

    public override void assign (Conquer.ConfigurationItem assign) {
        if (assign is IntegerConfigurationItem) {
            var ici = (IntegerConfigurationItem)assign;
            this.value = ici.value;
            this.min = ici.min;
            this.max = ici.max;
        } else {
            critical ("Can't reassign %s", this.id);
        }
    }
}

public class Conquer.StringConfigurationItem : Conquer.ConfigurationItem {
    public string @value { get; set; }

    public StringConfigurationItem (string name, string id, string description, string @default = "") {
        this.name = name;
        this.id = id;
        this.description = description;
        this.@value = @default;
    }

    public override void assign (Conquer.ConfigurationItem assign) {
        if (assign is StringConfigurationItem) {
            var sci = (StringConfigurationItem)assign;
            this.value = sci.value;
        } else {
            critical ("Can't reassign %s", this.id);
        }
    }
}

public class Conquer.BoolConfigurationItem : Conquer.ConfigurationItem {
    public bool @value { get; set; }

    public BoolConfigurationItem (string name, string id, string description, bool @default = false) {
        this.name = name;
        this.id = id;
        this.description = description;
        this.@value = @default;
    }

    public override void assign (Conquer.ConfigurationItem assign) {
        if (assign is BoolConfigurationItem) {
            var bci = (BoolConfigurationItem)assign;
            this.value = bci.value;
        } else {
            critical ("Can't reassign %s", this.id);
        }
    }
}
