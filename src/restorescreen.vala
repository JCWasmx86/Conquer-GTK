/* restorescreen.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/restorescreen.ui")]
    public class RestoreScreen : Gtk.Box {
        construct {
            this.model = new ListStore (typeof (Conquer.SavedGame));
            this.saves_list.bind_model (model, mapping_func);
            this.search_bar.search_changed.connect (() => {
                var text = this.search_bar.text.strip ();
                for (var i = 0; i < model.n_items; i++) {
                    var row = this.saves_list.get_row_at_index (i);
                    if (row == null)
                        continue; // Should never happen
                    var e = (SaveGameEntry) row;
                    row.visible = e.title.down ().contains (text.down ());
                }
            });
        }
        private GLib.ListStore model;
        [GtkChild]
        private unowned Gtk.SearchEntry search_bar;
        [GtkChild]
        private unowned Gtk.ListBox saves_list;
        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;

        internal void update (SavedGame[] games) {
            this.model.remove_all ();
            foreach (var s in games)
                this.model.append (s);
            for (var i = 0; i < model.n_items; i++) {
                var row = this.saves_list.get_row_at_index (i);
                if (row == null)
                    continue; // Should never happen
                var e = (SaveGameEntry) row;
                e.model = model;
            }
        }

        private static Gtk.Widget mapping_func (Object item) {
            var s = (SavedGame) item;
            return new SaveGameEntry (s);
        }

        internal void clear () {
            this.search_bar.text = "";
        }

        internal void show_save_loader_error (Conquer.SaveLoaderError e) {
            this.toast_overlay.add_toast (new Adw.Toast (e.message));
        }

        internal void show_save_error (Conquer.SaveError e) {
            this.toast_overlay.add_toast (new Adw.Toast (e.message));
        }
    }

    public class SaveGameEntry : Adw.ActionRow {
        internal GLib.ListStore model;
        public SaveGameEntry (SavedGame s) {
            this.title = s.name;
            this.subtitle = s.time.format ("%x %X");
            this.activatable = true;
            this.activated.connect (() => {
                var app = (Conquer.Application) GLib.Application.get_default ();
                app.restore_game_real (s);
            });
            var btn = new Gtk.Button.from_icon_name ("user-trash-symbolic");
            btn.get_style_context ().add_class ("destructive-action");
            btn.get_style_context ().add_class ("flat");
            btn.valign = Gtk.Align.CENTER;
            btn.halign = Gtk.Align.CENTER;
            btn.tooltip_text = _ ("Delete this saved game");
            btn.clicked.connect (() => {
                s.delete_data ();
                uint idx = 0;
                this.model.find (s, out idx);
                this.model.remove (idx);
            });
            this.add_suffix (btn);
        }
    }
}
