/* application.vala
 *
 * Copyright 2022 user
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
    public class Application : Adw.Application {
        public Application () {
            Object (application_id: "io.github.jcwasmx86.Conquer", flags: ApplicationFlags.DEFAULT_FLAGS);
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "quit", this.quit },
                { "start-game", this.start_game },
                { "show-main", this.show_main },
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", { "<primary>q" });
            this.set_accels_for_action ("conquer.save-game", { "<primary>s" });
            this.set_accels_for_action ("app.preferences", { "<primary>p" });
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) {
                win = new Conquer.Window (this);
            }
            win.present ();
        }

        private void on_about_action () {
            string[] developers = { "JCWasmx86" };
            var about = new Adw.AboutWindow () {
                transient_for = this.active_window,
                application_name = "Conquer",
                application_icon = "io.github.jcwasmx86.Conquer",
                developer_name = "JCWasmx86",
                version = "0.1.0",
                developers = developers,
                copyright = "© 2022 JCWasmx86",
            };

            about.present ();
        }

        private void on_preferences_action () {
            var window = new Adw.Window ();
            var bar = new Adw.HeaderBar ();
            bar.title_widget = new Adw.WindowTitle(_("Preferences"), "");
            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            box.append (bar);
            var main = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
            var stack = new Gtk.Stack ();
            stack.transition_type = Gtk.StackTransitionType.SLIDE_UP_DOWN;
            stack.hexpand = true;
            stack.vexpand = true;
            var sidebar = new Gtk.StackSidebar ();
            sidebar.stack = stack;
            sidebar.vexpand = true;
            var configs = ((Conquer.Window) this.active_window).context.find_configs ();
            foreach (var c in configs) {
                var name = c.name;
                var w = stack.get_child_by_name (name);
                if (w == null) {
                    var widget = new Conquer.ConfigWidget (c);
                    stack.add_titled (widget, name, name);
                } else {
                    ((Conquer.ConfigWidget)w).register (c);
                }
            }
            main.append (sidebar);
            main.append (stack);
            sidebar.stack = stack;
            box.append (main);
            box.vexpand = true;
            window.content = box;
            window.present ();
            window.set_size_request (600, 400);
        }

        private void start_game () {
            ((Conquer.Window) this.active_window).start_game ();
        }

        private void show_main () {
            ((Conquer.Window) this.active_window).show_main ();
        }
        internal void start_game_real (Conquer.Scenario s) {
            ((Conquer.Window) this.active_window).start_game_real (s);
        }
    }
}
