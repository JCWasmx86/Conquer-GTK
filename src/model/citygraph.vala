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
    public City[] cities;
    public double[, ] weights;

    public CityGraph (City[] cities) {
        this.cities = cities;
        this.weights = new double[cities.length, cities.length];
        for (var i = 0; i < cities.length; i++)
            for (var j = 0; j < cities.length; j++)
                this.weights[i, j] = i == j ? -1 : 0;
    }

    public void add_connection (uint from, uint to, double weight) requires (from != to) requires (weight >= 0) requires (from < this.cities.length) requires (to < this.cities.length) {
        this.weights[from, to] = weight;
        this.weights[to, from] = weight;
    }

    public bool direct_connection (City? from, City? to) requires (from != null) requires (to != null) requires (from != to) {
        return this.distance (from, to) > 0;
    }

    public double distance (City? from, City? to) requires (from != null) requires (to != null) requires (from != to) {
        return this.weights[from.index, to.index];
    }

    public double get_weight (uint from, uint to) requires (from < this.cities.length) requires (to < this.cities.length) {
        return this.weights[from, to];
    }

    public City[] cities_of_clan (Clan clan) {
        var ret = new City[0];
        foreach (var c in this.cities) {
            if (clan == c.clan)
                ret += c;
        }
        return ret;
    }

    public City[] reachable_enemy_cities (Clan clan, City[] own_cities) {
        var ret = new City[0];
        for (var i = 0; i < this.cities.length; i++) {
            if (this.cities[i].clan == clan)
                continue;
            foreach (var c in own_cities) {
                if (this.distance (c, this.cities[i]) > 0) {
                    ret += this.cities[i];
                    break;
                }
            }
        }
        return ret;
    }

    public City[] adjacent_cities (Clan clan, City middle) {
        var ret = new City[0];
        for (var i = 0; i < this.cities.length; i++) {
            if (middle == this.cities[i])
                continue;
            if (this.distance (this.cities[i], middle) > 0 && this.cities[i].clan == clan) {
                ret += this.cities[i];
            }
        }
        return ret;
    }

    public City[] border_cities (Clan clan) {
        var ret = new City[0];
        for (var i = 0; i < this.cities.length; i++) {
            var c = this.cities[i];
            if (c.clan != clan)
                continue;
            for (var j = 0; j < this.cities.length; j++) {
                if (i == j)
                    continue;
                if (this.weights[i, j] > 0) {
                    if (this.cities[j].clan != clan) {
                        ret += c;
                        break;
                    }
                }
            }
        }
        return ret;
    }

    public City[] inner_cities (Clan clan) {
        var ret = new City[0];
        for (var i = 0; i < this.cities.length; i++) {
            var c = this.cities[i];
            if (c.clan != clan)
                continue;
            var borders = false;
            for (var j = 0; j < this.cities.length; j++) {
                if (i == j)
                    continue;
                if (this.weights[i, j] > 0) {
                    if (this.cities[j].clan != clan) {
                        borders = true;
                        break;
                    }
                }
            }
            if (!borders) {
                ret += c;
            }
        }
        return ret;
    }
}
