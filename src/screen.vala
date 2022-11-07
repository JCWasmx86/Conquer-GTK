/* screen.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/conquerscreen.ui")]
    public class Screen : Gtk.Box, Conquer.MessageReceiver {
        construct {
            Conquer.MessageQueue.init ();
            Conquer.QUEUE.listen (this);
            this.next_round.clicked.connect (() => {
                this.game_state.one_round ();
                this.map.one_round ();
            });
        }
        private Conquer.GameState game_state;
        [GtkChild]
        private new unowned Conquer.Map map;
        [GtkChild]
        private unowned Gtk.Button next_round;
        // TODO: Let this be a listbox/listview?
        [GtkChild]
        private unowned Gtk.TextView event_view;

        internal void update (Conquer.GameState g) {
            this.game_state = g;
            this.map.update (g);
        }

        public void receive (Conquer.Message msg) {
            // TODO: Add colors
            if (msg is Conquer.InitMessage) {
                this.event_view.buffer.text = "";
            } else if (msg is Conquer.AttackMessage) {
                var am = (Conquer.AttackMessage)msg;
                Gtk.TextIter iter;
                this.event_view.buffer.get_end_iter (out iter);
                var str = am.result == AttackResult.FAIL ? "failed." : "conquered it.";
                this.event_view.buffer.insert_interactive (ref iter, "[Attack] %s (%s) attackes %s (%s) and %s\n".printf (am.from.name, am.from.clan.name, am.to.name, am.to.clan.name, str), -1, true);
            } else if (msg is Conquer.MoveMessage) {
                var mm = (Conquer.MoveMessage)msg;
                Gtk.TextIter iter;
                this.event_view.buffer.get_end_iter (out iter);
                this.event_view.buffer.insert_interactive (ref iter, "[Move] %s moves troops from %s to %s\n".printf (mm.from.clan.name, mm.from.name, mm.to.name), -1, true);
            }
        }
    }
}
