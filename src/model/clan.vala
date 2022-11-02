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
    public GLib.HashTable<Conquer.Resource, double?> resources { get; set; }
    protected double[] uses;

    construct {
        this.resources = new GLib.HashTable<Conquer.Resource, double?>(Conquer.Resource.hash_func, null);
        for (var i = 0; i < 9; i++) {
            this.resources[i] = 0;
        }
        this.uses = new double[9];
    }

    public virtual void add_resource (Resource r, double amount) {
        this.resources[r] = this.resources[r] + amount;
        if (this.resources[r] < 0)
            this.resources[r] = 0;
        this.uses[r] += amount;
    }

    public virtual void use_resource (Resource r, double amount) {
        this.resources[r] = this.resources[r] - amount;
        if (this.resources[r] < 0)
            this.resources[r] = 0;
        this.uses[r] -= amount;
    }

    public virtual void disband_soldiers (GameState g) {
        var has_to_disband = false;
        foreach (var d in this.uses)
            has_to_disband |= d < 0;
        if (has_to_disband) {
            var positive = false;
            var cities = g.city_list;
            var j = 0;
            uint64 disbanded_number = 0;
            while (!positive && j < 100000) {
                var new_array = new double[9];
                var disbanded = false;
                foreach (var c in cities) {
                    if (c.clan != this)
                        continue;
                    if (!disbanded && new Rand ().next_double () > 0.5) {
                        var tmp = c.soldiers;
                        c.disband_random ();
                        disbanded_number += (tmp - c.soldiers);
                        disbanded = true;
                    }
                    var total = c.calculate_resource_netto ();
                    for (var i = 0; i < 9; i++)
                        new_array[i] += total[i];
                }
                var has_to_continue = false;
                foreach (var d in this.uses) {
                    has_to_continue |= d < 0;
                }
                positive = has_to_continue;
                j++;
            }
            info ("[%s] Disbanded %llu soldiers", this.name, disbanded_number);
        }
        this.uses = new double[9];
    }
    // TODO: Upgrades for defense/attack
}

public interface Conquer.Strategy : GLib.Object {
    public abstract void play (Conquer.GameState state);
    public abstract string uuid ();
}
