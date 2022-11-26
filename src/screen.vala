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
            this.install_action ("conquer.save-game", null, (w, a) => {
                var self = (Conquer.Screen)w;
                self.save ();
            });
            this.install_action ("conquer.resign", null, (w, a) => {
                Conquer.QUEUE.emit (new Conquer.EndGameMessage (((Conquer.Screen)w).game_state, Conquer.GameResult.RESIGNED));
                ((Conquer.Screen)w).end ();
                ((Conquer.Window)(((Adw.Application)GLib.Application.get_default ()).active_window)).show_main ();
            });
            this.install_action ("conquer.quit-or-resign", null, (w, a) => {
                var active_window = (Conquer.Window)(((Adw.Application)GLib.Application.get_default ()).active_window);
                var dialog = new Adw.MessageDialog (active_window, _("Quit"), _("Do you really want to quit?"));
                dialog.add_response ("save", _("Save"));
                dialog.add_response ("quit", _("Quit"));
                dialog.add_response ("cancel", _("Cancel"));
                dialog.set_response_appearance ("save", Adw.ResponseAppearance.SUGGESTED);
                dialog.set_response_appearance ("quit", Adw.ResponseAppearance.DESTRUCTIVE);
                dialog.response.connect(r => {
                    if (r == "quit") {
                        Conquer.QUEUE.emit (new Conquer.EndGameMessage (((Conquer.Screen)w).game_state, Conquer.GameResult.RESIGNED));
                        ((Conquer.Screen)w).end ();
                        active_window.show_main ();
                    } else if (r == "cancel") {
                        // Do nothing
                    } else if (r == "save") {
                        var window = ((Conquer.Screen)w).save ();
                        if (window != null) {
                            ((Gtk.Widget)window).destroy.connect (() => {
                                Conquer.QUEUE.emit (new Conquer.EndGameMessage (((Conquer.Screen)w).game_state, Conquer.GameResult.SAVED));
                                ((Conquer.Screen)w).end ();
                                active_window.show_main ();
                            });
                        } else {
                            Conquer.QUEUE.emit (new Conquer.EndGameMessage (((Conquer.Screen)w).game_state, Conquer.GameResult.SAVED));
                            ((Conquer.Screen)w).end ();
                            active_window.show_main ();
                        }
                    }
                });
                dialog.present ();
            });
            this.next_round.clicked.connect (() => {
                this.game_state.one_round ();
                this.map.one_round ();
                this.clan_view.update (this.game_state);
                this.total_power.update ();
                this.economic_power.update ();
                this.economic_power.update ();
                this.check_result ();
            });
            this.quit.clicked.connect (() => {
                this.end ();
                ((Conquer.Window)(((Adw.Application)GLib.Application.get_default ()).active_window)).show_main ();
            });
            this.total_power.title.label = _("Total Power");
            this.economic_power.title.label = _("Economic Power");
            this.military_power.title.label = _("Military Power");
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
                        this.coins.label = _("Coins: %llu").printf (c.coins);
                }
            });
            this.clan_view.update_state.connect (() => {
                this.total_power.update ();
                this.economic_power.update ();
                this.economic_power.update ();
                this.clan_view.update (this.game_state);
                foreach (var c in this.game_state.clans) {
                    if (c.player)
                        this.coins.label = _("Coins: %llu").printf (c.coins);
                }
            });
        }
        private Conquer.GameState game_state;
        internal string? save_name;
        internal Conquer.Saver? saver;
        [GtkChild]
        private new unowned Conquer.Map map;
        [GtkChild]
        private unowned Gtk.Button next_round;
        [GtkChild]
        private unowned Gtk.Button quit;
        [GtkChild]
        private unowned Gtk.Label coins;
        [GtkChild]
        private unowned Gtk.Label status;
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
        private string? uri;
        private bool play;
        private MainLoop? loop;
        private dynamic Gst.Element? music_element;
        private double volume;


        internal void end () {
            info ("HERE, %p", this.loop);
            if (this.loop != null) {
                this.loop.get_context ().invoke (() => {
                    if (this.music_element != null)
                        this.music_element.set_state (Gst.State.NULL);
                    this.loop.quit ();
                    return Source.REMOVE;
                }, Priority.HIGH);
                this.loop.quit ();
                this.loop = null;
            }
            this.play = false;
        }

        void begin_music (bool victory) {
            this.uri = victory ? "file:///app/share/conquer/music/Victory.ogg" : "file:///app/share/conquer/music/Defeated.ogg";
            this.play = true;
            new Thread<void> ("music", this.play_music);
        }

        private void play_music () {
            while (this.play) {
                this.loop = new MainLoop ();
                dynamic Gst.Element play = Gst.ElementFactory.make ("playbin", "play");
                this.music_element = play;
                play.uri = this.uri;
                info ("URI: %s", play.uri);
                var bus = play.get_bus ();
                bus.add_watch (0, (b, m) => {
                    if (m.type == Gst.MessageType.ERROR) {
                        GLib.Error err;
                        string debug;
                        m.parse_error (out err, out debug);
                        critical ("%s: %s", err.message, debug);
                        loop.quit ();
                    } else if (!this.play) {
                        play.set_state (Gst.State.PAUSED);
                        loop.quit ();
                    } else if (m.type == Gst.MessageType.EOS) {
                        loop.quit ();
                    }
                    return true;
                });
                play.set_state (Gst.State.PLAYING);
                loop.run ();
                play.set_state (Gst.State.NULL);
                this.loop = null;
                this.music_element = null;
            }
        }

        internal void update (Conquer.GameState g) {
            this.game_state = g;
            this.quit.visible = false;
            this.status.visible = false;
            this.next_round.visible = true;
            this.coins.visible = true;
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
                    this.coins.label = _("Coins: %llu").printf (c.coins);
            }
            this.save_name = null;
            this.saver = null;
            this.end ();
        }

        internal void check_result (bool emit = true) {
            Clan? player_clan = null;
            foreach (var c in this.game_state.clans)
                if (c.player) {
                    player_clan = c;
                    break;
                }
            assert (player_clan != null);
            var cities = this.game_state.cities.cities_of_clan (player_clan);
            if (cities.length == 0) {
                this.quit.visible = true;
                this.status.visible = true;
                this.status.label = _("You lost!");
                this.next_round.visible = false;
                this.coins.visible = false;
                if (emit)
                    Conquer.QUEUE.emit (new Conquer.EndGameMessage (this.game_state, Conquer.GameResult.PLAYER_LOST));
                this.begin_music (false);
            } else if (cities.length == this.game_state.city_list.length) {
                this.quit.visible = true;
                this.status.visible = true;
                this.status.label = _("You won!");
                this.next_round.visible = false;
                this.coins.visible = false;
                if (emit)
                    Conquer.QUEUE.emit (new Conquer.EndGameMessage (this.game_state, Conquer.GameResult.PLAYER_WON));
                this.begin_music (true);
            }
        }

        private Adw.Window? save () {
            if (this.save_name != null) {
                var ctx = ((Conquer.Window)(((Adw.Application)GLib.Application.get_default ()).active_window)).context;
                ctx.save (this.game_state, this.save_name, this.saver);
                return null;
            }
            var window = new Adw.Window ();
            window.modal = true;
            var bar = new Adw.HeaderBar ();
            bar.title_widget = new Adw.WindowTitle (_("Save game"), "");
            var child = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
            child.append (bar);
            var ctx = ((Conquer.Window)(((Adw.Application)GLib.Application.get_default ()).active_window)).context;
            var savers = ctx.find_savers ();
            var savers_row = new Adw.ActionRow ();
            savers_row.title = _("Location");
            savers_row.subtitle = _("Where to save the game");
            var cbt = new Gtk.ComboBoxText ();
            for (var i = 0; i < savers.length; i++) {
                cbt.append ("%d".printf (i), savers[i].name);
            }
            cbt.active = 0;
            savers_row.add_suffix (cbt);
            var save_btn = new Gtk.Button.with_label (_("Save"));
            save_btn.get_style_context ().add_class ("suggested-action");
            var entry_row = new Adw.EntryRow ();
            entry_row.title = _("Name");
            entry_row.changed.connect (() => {
                var t = entry_row.text;
                var s = savers[cbt.active];
                if (s.name_is_available (t.strip ())) {
                    entry_row.get_style_context ().remove_class ("error");
                    save_btn.sensitive = true;
                } else {
                    entry_row.get_style_context ().add_class ("error");
                    save_btn.sensitive = false;
                }
            });
            child.append (entry_row);
            child.append (savers_row);
            child.append (save_btn);
            save_btn.clicked.connect (() => {
                this.save_name = entry_row.text.strip ();
                this.saver = savers[cbt.active];
                ctx.save (this.game_state, entry_row.text.strip (), savers[cbt.active]);
                ((Gtk.Widget)window).destroy ();
                window.destroy ();
            });
            var clamp = new Adw.Clamp ();
            clamp.maximum_size = 360;
            clamp.child = child;
            window.content = clamp;
            window.resizable = false;
            window.show ();
            return window;
        }

        public void receive (Conquer.Message msg) {
            // TODO: Add colors
            if (msg is Conquer.InitMessage) {
                this.event_view.buffer.text = "";
            } else if (msg is Conquer.AttackMessage) {
                var am = (Conquer.AttackMessage)msg;
                Gtk.TextIter iter;
                this.event_view.buffer.get_end_iter (out iter);
                var msgstr = "";
                if (am.result == AttackResult.FAIL)
                    msgstr = _("[Attack] %s (%s) attackes %s (%s) and failed.\n");
                else
                    msgstr = _("[Attack] %s (%s) attackes %s (%s) and conquered it.\n");
                this.event_view.buffer.insert_interactive (ref iter, msgstr.printf (am.from.name, am.from.clan.name, am.to.name, am.to.clan.name), -1, true);
            } else if (msg is Conquer.MoveMessage) {
                var mm = (Conquer.MoveMessage)msg;
                Gtk.TextIter iter;
                this.event_view.buffer.get_end_iter (out iter);
                this.event_view.buffer.insert_interactive (ref iter, _("[Move] %s moves troops from %s to %s\n").printf (mm.from.clan.name, mm.from.name, mm.to.name), -1, true);
            }
        }
    }
}
