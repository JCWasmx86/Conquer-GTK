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
                this.clan_view.update (this.game_state);
                this.total_power.update ();
                this.economic_power.update ();
                this.economic_power.update ();
            });
            this.total_power.title.label = "Total Power";
            this.economic_power.title.label = "Economic Power";
            this.military_power.title.label = "Military Power";
            this.economic_power.calc = (g, c) => {
                var cities = g.cities.cities_of_clan (c);
                var d = 0.0;
                foreach (var city in cities) {
                    d += city.people;
                    var vals = city.calculate_resource_netto ();
                    foreach (var v in vals)
                        d += v;
                }
                return d < 0 ? 0 : d;
            };
            this.military_power.calc = (g, c) => {
                var cities = g.cities.cities_of_clan (c);
                var d = 0.0;
                foreach (var city in cities) {
                    d += city.soldiers * city.defense_bonus;
                    d += city.defense;
                }
                return d;
            };
            this.total_power.calc = (g, c) => {
                return this.military_power.calc (g, c) + this.economic_power.calc (g, c);
            };
            this.map.updated.connect (() => {
                this.total_power.update ();
                this.economic_power.update ();
                this.economic_power.update ();
                this.clan_view.update (this.game_state);
                foreach (var c in this.game_state.clans) {
                    if (c.player)
                        this.coins.label = "Coins: %llu".printf (c.coins);
                }
            });
            this.clan_view.update_state.connect (() => {
                this.total_power.update ();
                this.economic_power.update ();
                this.economic_power.update ();
                this.clan_view.update (this.game_state);
                foreach (var c in this.game_state.clans) {
                    if (c.player)
                        this.coins.label = "Coins: %llu".printf (c.coins);
                }
            });
        }
        private Conquer.GameState game_state;
        [GtkChild]
        private new unowned Conquer.Map map;
        [GtkChild]
        private unowned Gtk.Button next_round;
        [GtkChild]
        private unowned Gtk.Label coins;
        // TODO: Let this be a listbox/listview?
        [GtkChild]
        private unowned Gtk.TextView event_view;
        [GtkChild]
        private unowned Conquer.Diagram total_power;
        [GtkChild]
        private unowned Conquer.Diagram economic_power;
        [GtkChild]
        private unowned Conquer.Diagram military_power;
        [GtkChild]
        private unowned Conquer.ClanInfo clan_view;

        internal void update (Conquer.GameState g) {
            this.game_state = g;
            this.total_power.init (g);
            this.military_power.init (g);
            this.economic_power.init (g);
            this.total_power.state = g;
            this.military_power.state = g;
            this.economic_power.state = g;
            this.map.update (g);
            this.total_power.update ();
            this.economic_power.update ();
            this.economic_power.update ();
            this.clan_view.update (g);
            foreach (var c in g.clans) {
                if (c.player)
                    this.coins.label = "Coins: %llu".printf (c.coins);
            }
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
