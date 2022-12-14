/* savetest.vala
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
namespace Conquer.Test {
    public static void main (string[] args) {
        typeof (Conquer.StartGameMessage).ensure ();
        Conquer.QUEUE = new Conquer.MessageQueue ();
        var ctx = new Conquer.Context (new Conquer.DefaultConfigLoader ());
        ctx.init ();
        var strategies = ctx.find_strategies ();
        var N = 50;
        var savers = ctx.find_savers ();
        var deser = ctx.find_deserializers ();
        for (var i = 0; i < N; i++) {
            var scenarios = ctx.find_scenarios ();
            foreach (var s in scenarios) {
                var s1 = s.load (strategies);
                while (true) {
                    s1.one_round ();
                    var clan = s1.city_list[0].clan;
                    var all_of_one = true;
                    for (var j = 0; j < s1.city_list.length; j++) {
                        if (s1.city_list[j].clan != clan) {
                            all_of_one = false;
                            break;
                        }
                    }
                    if (s1.round % 10000 == 0)
                        print ("Round %llu\n", s1.round);
                    ctx.save (s1, "temp____________", savers[0]);
                    var saved_games = ctx.find_saved_games ();
                    foreach (var sv in saved_games) {
                        if (sv.name == "temp____________") {
                            Conquer.Deserializer? des = null;
                            foreach (var d in deser) {
                                if (d.supports_uuid (sv.guid)) {
                                    des = d;
                                    break;
                                }
                            }
                            assert (des != null);
                            var bytes = sv.load ();
                            s1 = des.deserialize (bytes, strategies);
                            break;
                        }
                    }
                    if (all_of_one || s1.round == 1000) {
                        break;
                    }
                }
            }
            print ("Iteration %d\n", i);
        }
        var saved_games = ctx.find_saved_games ();
        foreach (var sv in saved_games) {
            if (sv.name == "temp____________") {
                sv.delete_data ();
                break;
            }
        }
    }
}
