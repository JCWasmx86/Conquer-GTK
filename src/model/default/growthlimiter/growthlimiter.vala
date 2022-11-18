/* growthlimiter.vala
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
public class Conquer.Default.GrowthLimiter : GLib.Object, Conquer.MessageReceiver {
    private static int SOFT_LIMIT = (750 * 1000);
    private static int HARD_LIMIT = (1250 * 1000);

    private Gee.Set<Conquer.City> cities;
    construct {
        this.cities = new Gee.HashSet<Conquer.City> ();
    }

    public void receive (Conquer.Message msg) {
        if (msg is Conquer.NewRoundMessage) {
            var state = ((Conquer.NewRoundMessage)msg).state;
            foreach (var c in state.city_list) {
                if (c.people > HARD_LIMIT) {
                    if (c.growth > 1) {
                        c.growth *= 0.95;
                    }
                    info ("City %s reached hard limit, growth = %.2lf", c.name, c.growth * 100 - 100);
                    this.cities.add (c);
                } else if (c.people > SOFT_LIMIT) {
                    if (c.growth > 1) {
                        c.growth *= 0.99;
                    }
                    info ("City %s reached soft limit, growth = %.2lf", c.name, c.growth * 100 - 100);
                    this.cities.add (c);
                } else if (c in this.cities) {
                    this.cities.remove (c);
                    while (c.growth < 1.0) {
                        c.growth *= 1.01;
                    }
                }
            }
        } else if (msg is Conquer.StartGameMessage) {
            this.cities.clear ();
        }
    }
}
public void peas_register_types (TypeModule module) {
    Conquer.QUEUE.listen (new Conquer.Default.GrowthLimiter ());
}
