/* cityinfo.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/cityinfo.ui")]
    public class CityInfo : Gtk.Box {
        construct {
            this.model = new Gtk.ListStore (2, typeof(string), typeof(string));
            this.city_info_list = new Gtk.TreeView ();
            this.kr = new Gtk.CellRendererText ();
            this.vr = new Gtk.CellRendererText ();
            this.city_info_list.insert_column_with_attributes (-1, "Key", this.kr, "text", 0, null);
            this.city_info_list.insert_column_with_data_func (-1, "Value", this.vr, (tc, cr, tm, iter) => {
                string str;
                tm.@get(iter, 1, ref str, -1);
                ((Gtk.CellRendererText)cr).markup = str;
            });
            this.city_info_list.enable_search = false;
            this.city_info_list.headers_visible = false;
            this.append (this.city_info_list);
        }
        private Gtk.ListStore model;
        private Gtk.CellRendererText kr;
        private Gtk.CellRendererText vr;
        private Gtk.TreeView city_info_list;

        internal void update (Conquer.City? c) {
            this.model.clear ();
            if (c == null)
                return;
            Gtk.TreeIter iter;
            this.model.append (out iter);
            this.model.@set (iter, 0, "Name", 1, c.name, -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "People", 1, "%llu".printf (c.people), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Soldiers", 1, "%llu".printf (c.soldiers), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Growth", 1, this.colorify("%.2lf%%".printf ((c.growth * 100) - 100)), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Defense", 1, "%llu".printf (c.defense), -1);
            this.model.append (out iter);
            this.model.@set (iter, 0, "Defense Bonus", 1, "%.2lf%%".printf (c.defense_bonus * 100 - 100), -1);
            var amount = c.calculate_resource_netto ();
            for (var i = 0; i < 9; i++) {
                this.model.append (out iter);
                this.model.@set (iter, 0, ((Resource)i).to_string (), 1, this.colorify("%.2lf".printf (amount[i])), -1);
            }
            this.city_info_list.set_model (this.model);
        }

        private string colorify (string s) requires (s.length > 0) {
            if (s[0] == '-') {
                return "<span foreground=\"red\">%s</span>".printf (s);
            }
            return "<span foreground=\"green\">%s</span>".printf (s);
        }
    }
}
