/* offensivealgorithm.vala
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
public class Conquer.Default.OffensiveStrategy : GLib.Object, Conquer.Strategy {
    public void play (Conquer.Clan clan, Conquer.GameState state) {
        // Do nothing
    }

    public string uuid () {
        return "0b41ca43-3872-421c-9b14-95b16260b9aa";
    }
}
public void peas_register_types(TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type(typeof (Conquer.Strategy), typeof (Conquer.Default.OffensiveStrategy));
}
