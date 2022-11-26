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
        construct {
            Conquer.MessageQueue.init ();
            this.listener = new DatabaseListener ();
            Conquer.QUEUE.listen (this.listener);
        }
        [GtkChild]
        private unowned Gtk.Stack main_stack;
        [GtkChild]
        private unowned Conquer.MainScreen main_screen;
        [GtkChild]
        private unowned Conquer.NewSelectionScreen selection_screen;
        [GtkChild]
        private unowned Conquer.RestoreScreen restore_screen;
        [GtkChild]
        private unowned Conquer.Screen conquer_screen;
        [GtkChild]
        private unowned Conquer.Statistics statistics;
        internal Context context;
        internal DatabaseListener listener;

        public Window (Gtk.Application app) {
            Object (application: app);
            this.main_stack.visible_child = this.main_screen;
            this.context = new Context (new Conquer.DefaultConfigLoader ());
            this.context.init ();
            this.maximize ();
        }

        internal void start_game () {
            var scenarios = this.context.find_scenarios ();
            this.main_stack.visible_child = this.selection_screen;
            this.selection_screen.update (scenarios);
        }

        internal void restore_game () {
            var games = this.context.find_saved_games ();
            this.main_stack.visible_child = this.restore_screen;
            this.restore_screen.update (games);
        }

        internal void show_main () {
            if (this.main_stack.visible_child == this.selection_screen)
                this.selection_screen.clear ();
            this.main_stack.visible_child = this.main_screen;
        }

        internal void show_statistics () {
            this.main_stack.visible_child = this.statistics;
            this.statistics.update (this.listener);
        }

        internal void restore_game_real (Conquer.SavedGame s) {
            var g = s.load (this.context.find_deserializers (), this.context.find_strategies ());
            assert (g != null);
            this.restore_screen.clear ();
            Conquer.QUEUE.emit (new StartGameMessage (g));
            this.main_stack.visible_child = this.conquer_screen;
            this.conquer_screen.update (g);
        }

        internal void start_game_real (Conquer.Scenario s) {
            var g = s.load (this.context.find_strategies ());
            this.selection_screen.clear ();
            Conquer.QUEUE.emit (new StartGameMessage (g));
            this.main_stack.visible_child = this.conquer_screen;
            this.conquer_screen.update (g);
        }
    }
}
