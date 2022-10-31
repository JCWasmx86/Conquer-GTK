/* city.vala
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
public class Conquer.City : GLib.Object {
    public double growth { get; set; }
    public string name { get; set; }
    public GLib.Bytes   icon_data { get; set; }
    public Clan clan { get; set; }
    public uint64 people { get; set; }
    public uint64 soldiers { get; set; }
    public uint64 x { get; set; }
    public uint64 y { get; set; }
    public uint64 defense { get; set; }
    public double defense_bonus { get; set; }
    public uint64 defense_level { get; set; default = 1; }
    public ResourceUpgrade[] upgrades;

    public City() {
        this.upgrades = new ResourceUpgrade[9];
        for (var i = 0; i < this.upgrades.length; i++) {
            this.upgrades[i] = new ResourceUpgrade ();
            this.upgrades[i].resource = (Conquer.Resource)i;
            this.upgrades[i].level = 1;
        }
    }

    public void grow () {
        // 1. Resources are mined
        // 2. Resources are used
        // 3. If not enough resources, first the number of soldiers is reduced
        //    then the number of people
    }
}

public class Conquer.ResourceUpgrade  : Object {
    public Conquer.Resource resource;
    public uint64 level;
    public double production;
}
