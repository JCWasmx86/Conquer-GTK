/* citygraph.vala
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
public class Conquer.CityGraph : GLib.Object {
    private unowned City[] cities;
    public double[, ] weights;

    public CityGraph (City[] cities) {
        this.cities = cities;
        this.weights = new double[cities.length, cities.length];
        for (var i = 0; i < cities.length; i++)
            for (var j = 0; j < cities.length; j++)
                this.weights[i, j] = i == j ? -1 : 0;
    }

    public void add_connection (uint from, uint to, double weight)
                                requires (from != to)
                                requires (weight >= 0)
                                requires (from < this.cities.length)
                                requires (to < this.cities.length) {
        this.weights[from, to] = weight;
        this.weights[to, from] = weight;
    }

    public double get_weight (uint from, uint to) requires (from < this.cities.length) requires (to < this.cities.length) {
        return this.weights[from, to];
    }
}
