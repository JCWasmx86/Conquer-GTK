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
    public GLib.Bytes icon_data { get; set; }
    public Clan clan { get; set; }
    public uint64 people { get; set; }
    public uint64 soldiers { get; set; }
    public uint64 x { get; set; }
    public uint64 y { get; set; }
    public uint64 defense { get; set; }
    public double defense_bonus { get; set; }
    public uint64 defense_level { get; set; default = 1; }
    public ResourceUpgrade[] upgrades;

    public City () {
        this.upgrades = new ResourceUpgrade[9];
        for (var i = 0; i < this.upgrades.length; i++) {
            this.upgrades[i] = new ResourceUpgrade ();
            this.upgrades[i].resource = (Conquer.Resource) i;
            this.upgrades[i].level = 1;
        }
    }

    public virtual void grow () {
        this.people = (uint64) (this.people * this.growth);
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_produced = this.people * upgrade.production;
            this.clan.add_resource (resource, amount_produced);
        }
    }

    public virtual void use_resources () {
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_used = this.soldiers * 1.1 * GLib.Math.sqrt (upgrade.production);
            this.clan.use_resource (resource, amount_used);
        }
    }

    public virtual uint64 costs_for_recruiting (uint64 n) {
        return n * 50;
    }

    public virtual uint64 maximum_recruitable_soldiers (bool stay_neutral) {
        if (!stay_neutral) {
            return uint64.min (this.people, this.clan.coins / 50);
        }
        var n = uint64.MAX;
        foreach (var upgrade in this.upgrades) {
            var amount_produced = this.people * upgrade.production;
            var amount_used = this.soldiers * 1.1 * GLib.Math.sqrt (upgrade.production);
            var diff = amount_produced - amount_used;
            if (diff < 0 && stay_neutral) {
                return 0;
            }
            var res = diff / (1.1 * GLib.Math.sqrt (upgrade.production));
            if (res <= 0)
                return 0;
            n = uint64.min (n, (uint64) res);
        }
        var coins = this.clan.coins;
        n = uint64.min (n, coins / 50);

        return uint64.min (n, this.people);
    }

    public virtual double[] calculate_resource_netto () {
        var ret = new double[9];
        foreach (var upgrade in this.upgrades) {
            var resource = upgrade.resource;
            var amount_produced = this.people * upgrade.production;
            var amount_used = this.soldiers * 1.1 * GLib.Math.sqrt (upgrade.production);
            ret[resource] = amount_produced - amount_used;
        }
        return ret;
    }

    public virtual void disband_random () {
        this.soldiers = (uint64) (this.soldiers * new Rand ().double_range (0.85, 0.99));
    }

    public virtual void recruit (uint64 n) requires (n <= this.people) requires (this.clan.coins >= n * 50) {
        this.people -= n;
        this.soldiers += n;
        this.clan.coins -= (n * 50);
    }

    public virtual void disband (uint64 n) requires (n <= this.soldiers) {
        this.people += n;
        this.soldiers -= n;
    }

    public uint64 costs_for_upgrade (Resource r) {
        var u = this.upgrades[r];
        return (uint64) ((u.level + 1) * 500 + Math.pow (u.level + 1, 3.5));
    }

    public virtual void upgrade (Resource r) {
        var u = this.upgrades[r];
        var costs = this.costs_for_upgrade (r);
        assert (costs <= this.clan.coins);
        var x = u.production;
        var new_value = x * (1 + (Math.fabs (Math.sin (0.2 * u.level) * 0.3) + 0.1));
        this.clan.coins -= (uint64)costs;
        u.level++;
        u.production = new_value;
    }
}

public class Conquer.ResourceUpgrade : Object {
    public Conquer.Resource resource;
    public uint64 level;
    public double production;
}
