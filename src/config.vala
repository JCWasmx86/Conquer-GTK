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
    private Configuration original;
    private Context ctx;
    public ConfigWidget (Conquer.Configuration c, Conquer.Context ctx) {
        this.orientation = Gtk.Orientation.VERTICAL;
        this.spacing = 2;
        this.original = c;
        this.rows = new ConfigurationRow[0];
        this.ctx = ctx;
        this.register (c);
    }

    public void register (Conquer.Configuration c) {
        assert (c.id == this.original.id);
        foreach (var row in c.configs) {
            Conquer.ConfigurationRow r = null;
            if (row is Conquer.BoolConfigurationItem) {
                r = new Conquer.BooleanConfigurationRow (row.name, row.description, ((Conquer.BoolConfigurationItem) row).value);
            } else if (row is Conquer.StringConfigurationItem) {
                r = new Conquer.StringConfigurationRow (row.name, row.description, ((Conquer.StringConfigurationItem) row).value);
            } else if (row is Conquer.IntegerConfigurationItem) {
                var ici = ((Conquer.IntegerConfigurationItem) row);
                r = new Conquer.IntConfigurationRow (row.name, row.description, ici.value, ici.min, ici.max);
            } else {
                assert_not_reached ();
            }
            r.id = row.id;
            r.updated.connect (() => {
                this.emit_updated ();
            });
            this.rows += r;
            this.append (r);
        }
    }

    void emit_updated () {
        var copy = new Conquer.DefaultConfig (this.original.id);
        foreach (var row in this.rows)
            copy.append (row.create ());
        this.ctx.emit_changed (copy);
    }
}
public abstract class Conquer.ConfigurationRow : Adw.ActionRow {
    public string id { get; set; }
    protected ConfigurationRow (string title, string description) {
        this.title = title;
        this.subtitle = description;
    }

    public signal void updated ();

    public abstract Conquer.ConfigurationItem create ();
}
public class Conquer.BooleanConfigurationRow : Conquer.ConfigurationRow {
    private Gtk.CheckButton check_box;
    internal BooleanConfigurationRow (string title, string description, bool val) {
        base (title, description);
        check_box = new Gtk.CheckButton ();
        check_box.active = val;
        check_box.toggled.connect (() => this.updated ());
        this.add_suffix (check_box);
    }

    public override Conquer.ConfigurationItem create () {
        return new Conquer.BoolConfigurationItem (this.title, this.id, this.subtitle, this.check_box.active);
    }
}
public class Conquer.StringConfigurationRow : Conquer.ConfigurationRow {
    private Gtk.Entry entry;
    internal StringConfigurationRow (string title, string description, string val) {
        base (title, description);
        entry = new Gtk.Entry ();
        entry.buffer.set_text (val.data);
        entry.hexpand = true;
        entry.changed.connect (() => this.updated ());
        this.add_suffix (entry);
    }

    public override Conquer.ConfigurationItem create () {
        return new Conquer.StringConfigurationItem (this.title, this.id, this.subtitle, this.entry.buffer.text);
    }
}
public class Conquer.IntConfigurationRow : Conquer.ConfigurationRow {
    private Gtk.SpinButton btn;
    internal IntConfigurationRow (string title, string description, int64 val, int64 min, int64 max) {
        base (title, description);
        btn = new Gtk.SpinButton.with_range (min, max, 1);
        btn.value = val;
        btn.changed.connect (() => this.updated ());
        this.add_suffix (btn);
    }

    public override Conquer.ConfigurationItem create () {
        var min = 0.0;
        var max = 0.0;
        btn.get_range (out min, out max);
        return new Conquer.IntegerConfigurationItem (this.title, this.id, this.subtitle, (int64) min, (int64) max, (int64) btn.value);
    }
}
