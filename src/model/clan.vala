/* clan.vala
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

public class Conquer.Clan : GLib.Object {
    public uint64 coins { get; set; }
    public string name { get; set; }
    public string color { get; set; }
    public bool player { get; set; }
    public Strategy? strategy { get; set; }
    // TODO: Upgrades for defense/attack
}

public interface Strategy : GLib.Object {
    public abstract void play (Conquer.GameState state);
    public abstract string uuid ();
}
