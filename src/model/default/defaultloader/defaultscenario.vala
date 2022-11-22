/* defaultscenario.vala
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
public class Conquer.DefaultScenario : Object, Conquer.Scenario {
    public string name { get; set; }
    public Icon? icon { get; set; default = null; }
    private string filename;
    private GLib.HashTable<string, Bytes> contents;

    public DefaultScenario (string file) {
        this.filename = file;
        this.contents = new GLib.HashTable<string, Bytes> (str_hash, str_equal);
    }

    public bool validate () {
        var archive = new Archive.Read ();
        archive.support_format_all ();
        archive.support_filter_all ();
        if (archive.open_filename (this.filename, 10240) != Archive.Result.OK) {
            info ("Unable to open %s: %s (%d)", this.filename, archive.error_string (), archive.errno ());
            return false;
        }
        unowned Archive.Entry entry;
        Archive.Result last_result;
        while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
            var size = entry.size ();
            var pathname = entry.pathname ();
            while (pathname.has_prefix ("../"))
                pathname = pathname.substring (3);
            var parts = pathname.split ("/");
            var component = parts.length == 0 ? pathname : parts[parts.length - 1];
            info ("Entry %s size %lld", component, size);
            var data = new uint8[size];
            var n = archive.read_data (data);
            if (size != n) {
                info ("Error reading entry %s from %s: Expected %lld bytes, got %u", component, this.filename, size, n);
                return false;
            }
            this.contents[component] = new GLib.Bytes (data);
        }
        if (!this.contents.contains ("metadata.json")) {
            return false;
        }
        try {
            var metadata = Json.gobject_from_data (typeof (Conquer.DefaultMetadata),
                                                   (string) this.contents["metadata.json"].get_data (),
                                                   this.contents["metadata.json"].length) as DefaultMetadata;
            info ("Scenario %s has version %d", metadata.name, metadata.version);
            this.name = metadata.name;
        } catch (Error e) {
            info ("%s", e.message);
            return false;
        }
        return true;
    }

    public GameState load (Conquer.Strategy[] strategies) {
        var ret = new Conquer.GameState ();
        ret.name = this.name;
        var clans = new Clan[0];
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) this.contents["players.json"].get_data (),
                                                   this.contents["players.json"].length);
            var node = parser.get_root ();
            assert (node.get_node_type () == Json.NodeType.ARRAY);
            var array = node.get_array ();
            var idx = 0;
            foreach (var n in array.get_elements ()) {
                assert (n.get_node_type () == Json.NodeType.OBJECT);
                var obj = n.get_object ();
                var c = new Clan ();
                c.coins = obj.get_int_member ("coins");
                c.name = obj.get_string_member ("name");
                c.color = obj.get_string_member ("color");
                c.player = obj.get_boolean_member ("player");
                var expected_uuid = obj.get_string_member ("strategy");
                info ("Clan %s has strategy %s", c.name, expected_uuid);
                foreach (var s in strategies) {
                    if (s.uuid () == expected_uuid) {
                        var t = s.get_type ();
                        info ("Strategy for %s is a %s", c.name, t.name ());
                        var new_strategy = GLib.Object.new (t, null);
                        c.strategy = (Conquer.Strategy)new_strategy;
                    }
                }
                if (c.strategy == null)
                    info ("No strategy with UUID %s found for %s", c.name, expected_uuid);
                c.index = idx;
                idx++;
                clans += c;
            }
        } catch (Error e) {
            error ("Whoops: %s", e.message);
        }
        var cities = new City[0];
        var idx = 0;
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) this.contents["cities.json"].get_data (),
                                                   this.contents["cities.json"].length);
            var node = parser.get_root ();
            assert (node.get_node_type () == Json.NodeType.ARRAY);
            var array = node.get_array ();
            foreach (var n in array.get_elements ()) {
                assert (n.get_node_type () == Json.NodeType.OBJECT);
                var c = new Conquer.City ();
                var obj = n.get_object ();
                c.growth = obj.get_double_member ("growth");
                c.name = obj.get_string_member ("name");
                var data = this.contents[obj.get_string_member ("icon")];
                assert (data != null);
                c.icon_data = new GLib.Bytes.from_bytes (data, 0, data.length);
                c.clan = clans[obj.get_int_member ("clan_id")];
                c.people = obj.get_int_member ("people");
                c.soldiers = obj.get_int_member ("soldiers");
                c.x = obj.get_int_member ("x");
                c.y = obj.get_int_member ("y");
                c.defense = obj.get_int_member ("defense");
                c.defense_bonus = obj.get_double_member ("defense_bonus");
                c.people = obj.get_int_member ("people");
                var resources = obj.get_object_member ("resources");
                foreach (var r in resources.get_members ()) {
                    var val = resources.get_double_member (r);
                    c.upgrades[(uint)Resource.from_string (r)].production = val;
                }
                c.index = idx;
                cities += c;
                idx++;
            }
        } catch (Error e) {
            error ("Whoops: %s", e.message);
        }
        ret.city_list = cities;
        ret.clans = clans;
        var graph = new CityGraph (cities);
        try {
            var parser = new Json.Parser ();
            parser.load_from_data ((string) this.contents["map.json"].get_data (),
                                                   this.contents["map.json"].length);
            var node = parser.get_root ();
            assert (node.get_node_type () == Json.NodeType.ARRAY);
            var array = node.get_array ();
            foreach (var n in array.get_elements ()) {
                assert (n.get_node_type () == Json.NodeType.OBJECT);
                var obj = n.get_object ();
                var from = obj.get_int_member ("from");
                var to = obj.get_int_member ("to");
                var distance = obj.get_double_member ("distance");
                graph.add_connection ((uint)from, (uint)to, distance);
            }
        } catch (Error e) {
            error ("Whoops: %s", e.message);
        }
        ret.cities = graph;
        var bg = this.contents["background.png"];
        assert (bg != null);
        ret.background_image_data = new GLib.Bytes.from_bytes (bg, 0, bg.length);
        ret.guid = "84d37b4b-0d3c-4061-a0a5-468c37b125cd";
        ret.uuid = GLib.Uuid.string_random ();
        info ("Game has UUID %s", ret.uuid);
        return ret;
    }
}

private class Conquer.DefaultMetadata : Object {
    public string name { get; set; }
    public int version { get; set; default = 1; }
}
