/* window.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/window.ui")]
    public class Window : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Gtk.Stack main_stack;
        [GtkChild]
        private unowned Conquer.MainScreen main_screen;
        [GtkChild]
        private unowned Conquer.NewSelectionScreen selection_screen;
        private Context context;

        public Window (Gtk.Application app) {
            Object (application: app);
            this.main_stack.visible_child = this.main_screen;
            this.context = new Context();
        }

        internal void start_game() {
            var scenarios = this.context.find_scenarios ();
            this.main_stack.visible_child = this.selection_screen;
            this.selection_screen.update (scenarios);
        }
    }
}
