/* gamestate.vala
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
public class Conquer.GameState : Object {
    public string name;
    public CityGraph cities;
    public City[] city_list;
    public Clan[] clans;
    public uint round;
    public GLib.Bytes background_image_data;

    public GameState () {
        this.round = 1;
    }

    public virtual void one_round () {
        info ("Playing round %u", this.round);
        foreach (var clan in this.clans) {
            if (clan.player || clan.strategy == null)
                continue;
            clan.strategy.play (clan, this);
        }
        foreach (var city in this.city_list) {
            city.grow ();
        }
        foreach (var city in this.city_list) {
            city.use_resources ();
        }
        foreach (var clan in this.clans) {
            clan.disband_soldiers (this);
        }
        foreach (var city in this.city_list) {
            city.clan.coins += city.people;
        }
        this.round++;
    }

    public virtual uint64 maximum_number_of_soliders_to_move (City from, City to) {
        var distance = this.cities.distance (from, to);
        if (distance <= 0)
            return 0;
        var costs_per_soldier = distance * 1.2;
        var amount_for_all = from.soldiers * costs_per_soldier;
        if (amount_for_all <= from.clan.coins)
            return from.soldiers;
        return (uint64) (from.clan.coins / costs_per_soldier);
    }

    public virtual void move (City from, City to, uint64 n) requires (from != null) requires (to != null) requires (from != to) requires (n != 0) requires (this.cities.distance (from, to) > 0) {
        var distance = this.cities.distance (from, to);
        var costs = distance * 1.2 * n;
        assert (costs <= from.clan.coins);
        from.soldiers -= n;
        from.clan.coins -= (uint64) costs;
        to.soldiers += n;
        Conquer.QUEUE.emit (new MoveMessage (from, to, n));
    }

    public virtual Conquer.AttackResult attack (City from, City to, uint64 n) requires (from != null) requires (to != null) requires (from != to) requires (n != 0) requires (this.cities.distance (from, to) > 0) {
        var distance = this.cities.distance (from, to);
        var costs = distance * 1.2 * n;
        assert (costs <= from.clan.coins);
        var attacking_power = (double) n;
        var defense_power = to.soldiers * to.defense_bonus;
        var difference = attacking_power - defense_power;
        info ("Attacking %s from %s with %llu soldiers (Power %lf vs %lf)", to.name, from.name, n, attacking_power, defense_power);
        from.soldiers -= n;
        from.clan.coins -= (uint64) costs;
        var result = Conquer.AttackResult.FAIL;
        if (difference > 0) {
            if (difference > to.defense) {
                // We got the city
                to.soldiers = (uint64) difference;
                to.clan = from.clan;
                info ("City got conquered");
                to.people = (uint64) (to.people * GLib.Random.double_range (0.75, 0.95));
                result = Conquer.AttackResult.SUCCESS;
            } else {
                to.soldiers = 0;
                info ("All enemy soldiers were killed, but the city couldn't be conquered");
            }
        } else {
            var cleaned_diff = -(difference / to.defense_bonus);
            to.soldiers = (uint64) cleaned_diff;
            info ("Attack failed");
        }
        Conquer.QUEUE.emit (new AttackMessage (from, to, n, result));
        return result;
    }
}

public enum Conquer.AttackResult {
    SUCCESS, FAIL;
}
