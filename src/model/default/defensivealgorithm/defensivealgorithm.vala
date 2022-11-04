/* defensivealgorithm.vala
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
public class Conquer.Default.DefensiveStrategy : GLib.Object, Conquer.Strategy {
    public void play (Conquer.Clan clan, Conquer.GameState state) {
        var own_cities = state.cities.cities_of_clan (clan);
        info ("[Defensive] Have %d cities", own_cities.length);
        var all_are_neutral = true;
        foreach (var c in own_cities) {
            var netto = c.calculate_resource_netto ();
            var is_neutral = true;
            foreach (var r in netto)
                is_neutral &= r >= 0;
            info ("[Defensive] %s has neutral: %s", c.name, is_neutral.to_string ());
            all_are_neutral &= is_neutral;
            // TODO: Update defense if is_neutral
            if (is_neutral)
                continue;
        }
        info ("[Defensive] All are neutral: %s", all_are_neutral.to_string ());
        if (all_are_neutral) {
            foreach (var c in own_cities) {
                var n = c.maximum_recruitable_soldiers (true);
                var real_amount = (uint64)(n * 0.8);
                info ("[Defensive] Could recruit %llu soldiers in %s, but will only recruit %llu", n, c.name, real_amount);
                c.recruit (real_amount);
            }
        }
        if (GLib.Random.next_double () < 0.85) {
            return;
        }
        var enemy_cities = state.cities.reachable_enemy_cities (clan, own_cities);
        for (var i = 0; i < enemy_cities.length; i++) {
            var a = GLib.Random.next_int () % enemy_cities.length;
            var b = GLib.Random.next_int () % enemy_cities.length;
            var tmp = enemy_cities[a];
            enemy_cities[a] = enemy_cities[b];
            enemy_cities[b] = tmp;
        }
        foreach (var ec in enemy_cities) {
            var neighbors = state.cities.adjacent_cities (clan, ec);
            GLib.qsort_with_data<City> (neighbors, sizeof(City), (a,b) => {
                assert (a != null);
                assert (b != null);
                if (a.soldiers == b.soldiers)
                    return 0;
                return a.soldiers < b.soldiers ? 1 : -1;
            });
            info ("[Defensive] Enemy city %s", ec.name);
            foreach (var c in neighbors) {
                var max_num = state.maximum_number_of_soliders_to_move (c, ec);
                info ("[Defensive] %s -> %s: %llu", c.name, ec.name, max_num);
                var real_num = (uint64)(max_num * 0.8);
                state.attack (c, ec, real_num);
            }
        }
    }

    public string uuid () {
        return "f9adeac4-95a5-46e8-805e-69473d719f23";
    }
}
public void peas_register_types(TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type(typeof (Conquer.Strategy), typeof (Conquer.Default.DefensiveStrategy));
}
