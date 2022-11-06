/* cityactions.vala
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
[GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/cityactions.ui")]
public class Conquer.CityActionScreen : Gtk.Box {
    construct {
        this.recruit.clicked.connect (() => {
            this.change_soldiers (true);
        });
        this.disband.clicked.connect (() => {
            this.change_soldiers (false);
        });
    }
    private GameState state;
    private City? city;
    [GtkChild]
    private unowned Gtk.Button recruit;
    [GtkChild]
    private unowned Gtk.Button disband;

    private void change_soldiers (bool recruit) {
        assert (city != null);
        var window = new Adw.Window ();
        var bar = new Adw.HeaderBar ();
        bar.title_widget = new Adw.WindowTitle (recruit ? "Recruit soldiers" : "Disband soldiers", "");
        var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        child.append (bar);
        var label = new Gtk.Label ("How many soldiers do you want to " + (recruit ? "recruit" : "disband") + "?");
        child.append (label);
        var max = recruit ? this.city.maximum_recruitable_soldiers (false) : this.city.soldiers;
        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, max == 0 ? 1 : max, 1);
        scale.sensitive = max != 0;
        scale.draw_value = true;
        scale.digits = 0;
        child.append (scale);
        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        var suggested = new Gtk.Button.with_label (recruit ? "Recruit" : "Disband");
        suggested.hexpand = true;
        suggested.sensitive = false;
        suggested.get_style_context ().add_class ("suggested-action");
        var abort = new Gtk.Button.with_label ("Cancel");
        abort.hexpand = true;
        scale.value_changed.connect (() => {
            suggested.sensitive = scale.get_value () != 0;
        });
        abort.get_style_context ().add_class ("destructive-action");
        button_box.append (abort);
        button_box.append (suggested);
        button_box.hexpand = true;
        if (recruit) {
            var lbl = new Gtk.Label ("Costs: 0 coins");
            scale.value_changed.connect (() => {
                lbl.set_text ("Costs: %llu coins".printf (this.city.costs_for_recruiting ((uint64) scale.get_value ())));
            });
            child.append (lbl);
        }
        child.append (button_box);
        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 360;
        clamp.child = child;
        window.content = clamp;
        window.show ();
        abort.clicked.connect (() => {
            window.destroy ();
        });
        suggested.clicked.connect (() => {
            if (recruit) {
                this.city.recruit ((uint64) scale.get_value ());
            } else {
                this.city.disband ((uint64) scale.get_value ());
            }
            this.update_state ();
            window.destroy ();
        });
    }

    internal void update (GameState state, City? city) {
        this.city = city;
        this.state = state;
    }

    internal signal void update_state ();
}
