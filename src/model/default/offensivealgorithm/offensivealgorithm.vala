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
        var inner_cities = state.cities.inner_cities (clan);
        var border_cities = state.cities.border_cities (clan);
        foreach (var ic in inner_cities) {
            foreach (var bc in border_cities) {
                if (state.cities.distance (ic, bc) > 0) {
                    var n = state.maximum_number_of_soliders_to_move (ic, bc);
                    if (n != 0) {
                        state.move (ic, bc, n);
                        info ("[Aggressive] Moving %llu troops from %s to %s", n, ic.name, bc.name);
                    }
                }
                if (ic.soldiers == 0)
                    break;
            }
            if (ic.soldiers > 0)
                ic.disband (ic.soldiers);
        }
        if (border_cities.length != 0) {
            var random = border_cities[Random.next_int () % border_cities.length];
            var cities = state.cities.reachable_enemy_cities (clan, new City[1] { random });
            if (cities.length != 0) {
                var next_city = cities[Random.next_int () % cities.length];
                info ("[Aggressive] First attacked city from %s is %s", random.name, next_city.name);
                while (true) {
                    var n = state.maximum_number_of_soliders_to_move (random, next_city);
                    if (n == 0) {
                        info ("[Aggressive] Stopping as no soldiers left");
                        break;
                    }
                    var res = state.attack (random, next_city, n);
                    if (res == Conquer.AttackResult.FAIL) {
                        info ("[Aggressive] Stopping as attack failed");
                        break;
                    }
                    random = next_city;
                    cities = state.cities.reachable_enemy_cities (clan, new City[1] { random });
                    if (cities.length == 0) {
                        info ("[Aggressive] Stopping due to no enemy cities left");
                        break;
                    }
                    next_city = cities[Random.next_int () % cities.length];
                    info ("[Aggressive] Next city to attack is %s", next_city.name);
                }
            }
        }
        foreach (var bc in border_cities) {
            var n = bc.maximum_recruitable_soldiers (false);
            if (n <= 10)
                continue;
            bc.recruit (n);
            info ("[Aggressive] Recruiting %llu in %s", n, bc.name);
        }
    }

    public string uuid () {
        return "0b41ca43-3872-421c-9b14-95b16260b9aa";
    }
}
public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Strategy), typeof (Conquer.Default.OffensiveStrategy));
}
