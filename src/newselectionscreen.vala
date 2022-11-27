/* newselectionscreen.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/newselectionscreen.ui")]
    public class NewSelectionScreen : Gtk.Box {
        construct {
            this.model = new ListStore (typeof (Conquer.Scenario));
            this.scenario_list.bind_model (model, mapping_func);
            this.search_bar.search_changed.connect (() => {
                var text = this.search_bar.text.strip ();
                for (var i = 0; i < model.n_items; i++) {
                    var row = this.scenario_list.get_row_at_index (i);
                    if (row == null)
                        continue; // Should never happen
                    var e = (ScenarioEntry) row;
                    row.visible = e.title.down ().contains (text.down ());
                }
            });
        }
        private GLib.ListStore model;
        [GtkChild]
        private unowned Gtk.SearchEntry search_bar;
        [GtkChild]
        private unowned Gtk.ListBox scenario_list;
        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;

        internal void update(Scenario[] scenarios) {
            this.model.remove_all ();
            foreach (var s in scenarios)
                this.model.append (s);
        }

        private static Gtk.Widget mapping_func (Object item) {
            var s = (Scenario)item;
            return new ScenarioEntry (s);
        }

        internal void clear () {
            this.search_bar.text = "";
        }

        internal void show_scenario_loader_error (Conquer.ScenarioLoaderError e) {
            this.toast_overlay.add_toast (new Adw.Toast (e.message));
        }

        internal void show_scenario_error (Conquer.ScenarioError e) {
            this.toast_overlay.add_toast (new Adw.Toast (e.message));
        }
    }

    public class ScenarioEntry : Adw.ActionRow {
        public ScenarioEntry (Scenario s) {
            this.title = s.name;
            this.activatable = true;
            this.activated.connect (() => {
                var app = (Conquer.Application)GLib.Application.get_default ();
                app.start_game_real (s);
            });
        }
    }
}
