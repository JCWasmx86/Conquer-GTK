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
        this.people = (uint64) (this.people * this.growth);
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_produced = this.people * upgrade.production;
            this.clan.add_resource(resource, amount_produced);
        }
    }

    public void use_resources () {
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_used = this.soldiers * 1.1 * GLib.Math.sqrt(upgrade.production);
            this.clan.use_resource(resource, amount_used);
        }
    }

    public double[] calculate_resource_netto () {
        var ret = new double[9];
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_produced = this.people * upgrade.production;
            var amount_used = this.soldiers * 1.1 * GLib.Math.sqrt(upgrade.production);
            ret[resource] = amount_produced - amount_used;
        }
        return ret;
    }

    public void disband_random () {
        this.soldiers = (uint64) (this.soldiers * new Rand ().double_range (0.85, 0.99));
    }
}

public class Conquer.ResourceUpgrade  : Object {
    public Conquer.Resource resource;
    public uint64 level;
    public double production;
}
