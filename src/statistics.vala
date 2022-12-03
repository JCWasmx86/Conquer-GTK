/* statistics.vala
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
[GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/statistics.ui")]
public class Conquer.Statistics : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Label lbl_played_games;
    [GtkChild]
    private unowned Gtk.Label lbl_won_games;
    [GtkChild]
    private unowned Gtk.Label lbl_lost_games;
    [GtkChild]
    private unowned Gtk.Label lbl_resigned_games;
    internal void update (Conquer.DatabaseListener dl) {
        // TODO: This is ugly
        this.lbl_played_games.label = _ ("Total games played: %lld").printf (dl.number_of_played_games ());
        this.lbl_won_games.label = _ ("Games won: %lld").printf (dl.of_type (Conquer.GameResult.PLAYER_WON));
        this.lbl_lost_games.label = _ ("Games lost: %lld").printf (dl.of_type (Conquer.GameResult.PLAYER_LOST));
        this.lbl_resigned_games.label = _ ("Games resigned from: %lld").printf (dl.of_type (Conquer.GameResult.RESIGNED));
    }
}
