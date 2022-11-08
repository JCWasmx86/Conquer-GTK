/* clan_info.vala
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
namespace Conquer {
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/claninfo.ui")]
    public class ClanInfo : Gtk.Box {
        construct {
            this.model = new Gtk.ListStore (2, typeof (string), typeof (string));
            this.clan_info_list = new Gtk.TreeView ();
            this.kr = new Gtk.CellRendererText ();
            this.vr = new Gtk.CellRendererText ();
            this.clan_info_list.insert_column_with_attributes (-1, "Key", this.kr, "text", 0, null);
            this.clan_info_list.insert_column_with_data_func (-1, "Value", this.vr, (tc, cr, tm, iter) => {
                string str;
                tm.@get (iter, 1, ref str, -1);
                ((Gtk.CellRendererText) cr).markup = str;
            });
            this.clan_info_list.enable_search = false;
            this.clan_info_list.headers_visible = false;
            this.left_side.prepend (this.clan_info_list);
            this.upgrade_attack.clicked.connect (() => {
                this.upgrade (true);
            });
            this.upgrade_defense.clicked.connect (() => {
                this.upgrade (false);
            });
        }
        private Gtk.ListStore model;
        private Gtk.CellRendererText kr;
        private Gtk.CellRendererText vr;
        private Gtk.TreeView clan_info_list;
        [GtkChild]
        private unowned Gtk.Box left_side;
        [GtkChild]
        private unowned Gtk.Box right_side;
        [GtkChild]
        private unowned Gtk.Button upgrade_attack;
        [GtkChild]
        private unowned Gtk.Button upgrade_defense;
        private Clan clan;

        internal void update (Conquer.GameState g) {
            this.model.clear ();
            var child = this.right_side.get_first_child ();
            while (child != null) {
                this.right_side.remove (child);
                child = this.right_side.get_first_child ();
            }
            Conquer.Clan ccc = null;
            foreach (var c in g.clans) {
                if (c.player) {
                    ccc = c;
                    break;
                }
            }
            this.clan = ccc;
            assert (clan != null);
            Gtk.TreeIter iter;
            this.model.append (out iter);
            this.model.@set (iter, 0, "Name", 1, clan.name, -1);
            var cities = g.cities.cities_of_clan (clan);
            uint64 n_soldiers = 0;
            uint64 n_people = 0;
            var production = new double[Resource.num ()];
            foreach (var c in cities) {
                n_soldiers += c.soldiers;
                n_people += c.people;
                var prods = c.calculate_resource_netto ();
                var is_negative = false;
                for (var i = 0; i < prods.length; i++) {
                    production[i] += prods[i];
                    is_negative |= prods[i] < 0;
                }
                var row = new Adw.ActionRow ();
                row.title = c.name;
                var pic = new Gtk.Label ("");
                pic.set_markup ("<big>%s</big>".printf (is_negative ? "🔴" : "🟢"));
                if (is_negative) {
                    pic.tooltip_text = "This city uses more resources than it produces";
                } else {
                    pic.tooltip_text = "This city uses produces resources than it uses";
                }
                row.add_suffix (pic);
                this.right_side.append (row);
            }
            this.model.append (out iter);
            this.model.@set (iter, 0, "Cities", 1, "%u".printf (cities.length), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "People", 1, "%llu".printf (n_people), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Soldiers", 1, "%llu".printf (n_soldiers), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Attack Bonus", 1, "%.2lf".printf (clan.attack_strength * 100 - 100), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Defense Bonus", 1, "%.2lf".printf (clan.defense_strength * 100 - 100), -1);
            for (var i = 0; i < production.length; i++) {
                this.model.append (out iter);
                this.model.@set (iter, 0, ((Resource) i).to_string (), 1, this.colorify ("%.2lf".printf (production[i])), -1);
            }
            this.clan_info_list.set_model (this.model);
        }

        private string colorify (string s) requires (s.length > 0) {
            if (s[0] == '-') {
                return "<span foreground=\"red\">%s</span>".printf (s);
            }
            return "<span foreground=\"green\">%s</span>".printf (s);
        }

        private void upgrade (bool attack) {
            var window = new Adw.Window ();
            var bar = new Adw.HeaderBar ();
            bar.title_widget = new Adw.WindowTitle ("Upgrade %s".printf (attack ? "Attack" : "Defense"), "");
            var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            child.append (bar);
            var coins = attack ? this.clan.costs_for_attack_upgrade () : this.clan.costs_for_defense_upgrade ();
            var costs = new Gtk.Label ("Costs: %llu coins".printf (coins));
            child.append (costs);
            var new_strength = attack ? this.clan.upgraded_attack_strength () : this.clan.upgraded_defense_strength ();
            var current = attack ? this.clan.attack_strength : this.clan.defense_strength;
            var strength = new Gtk.Label ("New %s bonus: %.2lf%% (+%.2f%%)".printf (attack ? "attack" : "defense", new_strength * 100 - 100, (new_strength - current) * 100));
            child.append (strength);
            var max = new Gtk.CheckButton.with_label ("Upgrade as far as possible");
            child.append (max);
            var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
            var suggested = new Gtk.Button.with_label ("Upgrade");
            suggested.hexpand = true;
            suggested.sensitive = coins <= this.clan.coins;
            suggested.get_style_context ().add_class ("suggested-action");
            var abort = new Gtk.Button.with_label ("Cancel");
            abort.hexpand = true;
            button_box.append (abort);
            button_box.append (suggested);
            button_box.hexpand = true;
            child.append (button_box);
            var clamp = new Adw.Clamp ();
            clamp.maximum_size = 360;
            clamp.child = child;
            window.content = clamp;
            window.resizable = false;
            window.show ();
            suggested.clicked.connect (() => {
                while ((attack ? clan.costs_for_attack_upgrade () : clan.costs_for_defense_upgrade ()) <= this.clan.coins) {
                    if (attack)
                        this.clan.upgrade_attack ();
                    else
                        this.clan.upgrade_defense ();
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
        internal signal void update_state ();
    }
}
