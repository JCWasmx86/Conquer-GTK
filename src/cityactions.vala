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
        this.defense_upgrade.clicked.connect (() => {
            this.upgrade_defense ();
        });
        this.food.clicked.connect (() => {
            this.upgrade (Resource.FOOD);
        });
        this.wood.clicked.connect (() => {
            this.upgrade (Resource.WOOD);
        });
        this.iron.clicked.connect (() => {
            this.upgrade (Resource.IRON);
        });
        this.stone.clicked.connect (() => {
            this.upgrade (Resource.IRON);
        });
    }
    private GameState state;
    private City? city;
    [GtkChild]
    private unowned Gtk.Button recruit;
    [GtkChild]
    private unowned Gtk.Button disband;
    [GtkChild]
    private unowned Gtk.Button defense_upgrade;
    [GtkChild]
    private unowned Gtk.Button food;
    [GtkChild]
    private unowned Gtk.Button wood;
    [GtkChild]
    private unowned Gtk.Button iron;
    [GtkChild]
    private unowned Gtk.Button stone;

    private void upgrade (Resource r) {
        assert (city != null);
        var window = new Adw.Window ();
        var bar = new Adw.HeaderBar ();
        bar.title_widget = new Adw.WindowTitle (_ ("Upgrade %s").printf (Shared.from_resource (r)), "");
        bar.show_end_title_buttons = false;
        var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        child.append (bar);
        var coins = this.city.costs_for_upgrade (r);
        var costs = new Gtk.Label (_ ("Costs: %llu coins").printf (coins));
        child.append (costs);
        var new_production = this.city.upgraded_production (r);
        var prod = new Gtk.Label (_ ("New production: %.2lf (+%.2lf)").printf (new_production, new_production - this.city.upgrades[r].production));
        child.append (prod);
        var max = new Gtk.CheckButton.with_label (_ ("Upgrade as far as possible"));
        child.append (max);
        var suggested = new Gtk.Button.with_label (_ ("Upgrade"));
        suggested.hexpand = true;
        suggested.sensitive = coins <= this.city.clan.coins;
        suggested.get_style_context ().add_class ("suggested-action");
        var abort = new Gtk.Button.with_label (_ ("Cancel"));
        abort.hexpand = true;
        bar.pack_start (abort);
        bar.pack_end (suggested);
        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 360;
        clamp.child = child;
        window.content = clamp;
        window.resizable = false;
        window.modal = true;
        window.show ();
        suggested.clicked.connect (() => {
            while (this.city.costs_for_upgrade (r) <= this.city.clan.coins) {
                this.city.upgrade (r);
                if (!max.active)
                    break;
            }
            this.update_state ();
            window.destroy ();
        });
        abort.clicked.connect (() => {
            window.destroy ();
        });
    }

    private void upgrade_defense () {
        assert (city != null);
        var window = new Adw.Window ();
        window.modal = true;
        var bar = new Adw.HeaderBar ();
        bar.title_widget = new Adw.WindowTitle (_ ("Upgrade defense"), "");
        bar.show_end_title_buttons = false;
        var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        child.append (bar);
        var coins = this.city.costs_for_defense_upgrade ();
        var costs = new Gtk.Label (_ ("Costs: %llu coins").printf (coins));
        child.append (costs);
        var new_strength = this.city.upgraded_defense_strength ();
        var strength = new Gtk.Label (_ ("New defense strength: %llu (+%llu)").printf (new_strength, new_strength - this.city.defense));
        child.append (strength);
        var max = new Gtk.CheckButton.with_label (_ ("Upgrade as far as possible"));
        child.append (max);
        var suggested = new Gtk.Button.with_label (_ ("Upgrade"));
        suggested.hexpand = true;
        suggested.sensitive = coins <= this.city.clan.coins;
        suggested.get_style_context ().add_class ("suggested-action");
        var abort = new Gtk.Button.with_label (_ ("Cancel"));
        abort.hexpand = true;
        bar.pack_start (abort);
        bar.pack_end (suggested);
        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 360;
        clamp.child = child;
        window.content = clamp;
        window.resizable = false;
        window.show ();
        suggested.clicked.connect (() => {
            while (this.city.costs_for_defense_upgrade () <= this.city.clan.coins) {
                this.city.upgrade_defense ();
                if (!max.active)
                    break;
            }
            this.update_state ();
            window.destroy ();
        });
        abort.clicked.connect (() => {
            window.destroy ();
        });
    }

    private void change_soldiers (bool recruit) {
        assert (city != null);
        var window = new Adw.Window ();
        window.modal = true;
        var bar = new Adw.HeaderBar ();
        bar.title_widget = new Adw.WindowTitle (recruit ? _ ("Recruit soldiers") : _ ("Disband soldiers"), "");
        bar.show_end_title_buttons = false;
        var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        child.append (bar);
        var str = "";
        if (recruit)
            str = _ ("How many soliders do you want to recruit?");
        else
            str = _ ("How many soldiers do you want to disband?");
        var label = new Gtk.Label (str);
        child.append (label);
        var max = recruit ? this.city.maximum_recruitable_soldiers (false) : this.city.soldiers;
        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, max == 0 ? 1 : max, 1);
        scale.sensitive = max != 0;
        scale.draw_value = true;
        scale.digits = 0;
        var sclamp = new Adw.Clamp ();
        sclamp.child = scale;
        sclamp.maximum_size = 330;
        child.append (sclamp);
        var suggested = new Gtk.Button.with_label (recruit ? _ ("Recruit") : _ ("Disband"));
        suggested.hexpand = true;
        suggested.sensitive = false;
        suggested.get_style_context ().add_class ("suggested-action");
        var abort = new Gtk.Button.with_label (_ ("Cancel"));
        abort.hexpand = true;
        scale.value_changed.connect (() => {
            suggested.sensitive = scale.get_value () != 0;
        });
        if (recruit) {
            var lbl = new Gtk.Label (_ ("Costs: 0 coins"));
            scale.value_changed.connect (() => {
                lbl.set_text (_ ("Costs: %llu coins").printf (this.city.costs_for_recruiting ((uint64) scale.get_value ())));
            });
            child.append (lbl);
        }
        bar.pack_start (abort);
        bar.pack_end (suggested);
        var clamp = new Adw.Clamp ();
        clamp.maximum_size = 360;
        clamp.child = child;
        window.content = clamp;
        window.resizable = false;
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
