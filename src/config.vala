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
public class Conquer.ConfigWidget : Gtk.Box {
    private ConfigurationRow[] rows;
    public ConfigWidget (Conquer.Configuration c) {
        this.orientation = Gtk.Orientation.VERTICAL;
        this.spacing = 2;
        this.rows = new ConfigurationRow[0];
        foreach (var row in c.configs) {
            if (row is Conquer.BoolConfigurationItem) {
                var r = new Conquer.BooleanConfigurationRow (row.name, row.description, ((Conquer.BoolConfigurationItem)row).value);
                this.rows += r;
                this.append (r);
            } else if (row is Conquer.StringConfigurationItem) {
                var r = new Conquer.StringConfigurationRow (row.name, row.description, ((Conquer.StringConfigurationItem)row).value);
                this.rows += r;
                this.append (r);
            } else if (row is Conquer.IntegerConfigurationItem) {
                var ici = ((Conquer.IntegerConfigurationItem)row);
                var r = new Conquer.IntConfigurationRow (row.name, row.description, ici.value, ici.min, ici.max);
                this.rows += r;
                this.append (r);
            }
        }
    }
}
public abstract class Conquer.ConfigurationRow : Adw.ActionRow {
    protected ConfigurationRow (string title, string description) {
        this.title = title;
        this.subtitle = description;
    }
}
public class Conquer.BooleanConfigurationRow : Conquer.ConfigurationRow {
    internal BooleanConfigurationRow (string title, string description, bool val) {
        base (title, description);
        var check_box = new Gtk.CheckButton ();
        check_box.active = val;
        this.add_suffix (check_box);
    }
}
public class Conquer.StringConfigurationRow : Conquer.ConfigurationRow {
    internal StringConfigurationRow (string title, string description, string val) {
        base (title, description);
        var entry = new Gtk.Entry ();
        entry.buffer.set_text (val.data);
        entry.hexpand = true;
        this.add_suffix (entry);
    }
}
public class Conquer.IntConfigurationRow : Conquer.ConfigurationRow {
    internal IntConfigurationRow (string title, string description, int64 val, int64 min, int64 max) {
        base (title, description);
        var entry = new Gtk.SpinButton.with_range (min, max, 1);
        entry.value = val;
        this.add_suffix (entry);
    }
}
