/* defaultsaver.vala
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
public class Conquer.Default.SaverConfig : GLib.Object, Conquer.Configuration {
    public string name { get; set; }
    public string id { get; set; }
    public GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }
    construct {
        this.name = "General";
        this.id = "general";
        var c = new Conquer.StringConfigurationItem ("Storage location for saved games", "storage.location", "Where to store the saved games.", Environment.get_user_data_dir () + "/conquer/saves");
        this.configs.append_val ((!) c);
    }
}

internal class Conquer.Default.SaverMetadata : GLib.Object {
    public string name { get; set; }
    public string uuid { get; set; }
    public int64 time { get; set; }
}

public class Conquer.Default.Saver : GLib.Object, Conquer.Saver {
    // TODO: i18n
    public string name { get; protected set; default = "Disk"; }

    public bool name_is_available (string name) {
        var base_dir = Environment.get_user_data_dir () + "/conquer/saves";
        var filename = "%x%x.save".printf (GLib.str_hash (name), GLib.str_hash (name + name));
        return !File.new_build_filename (base_dir, filename).query_exists ();
    }

    public void save (string name, string uuid, GLib.Bytes data) {
        var base_dir = Environment.get_user_data_dir () + "/conquer/saves";
        var filename = "%x%x.save".printf (GLib.str_hash (name), GLib.str_hash (name + name));
        var dir = File.new_build_filename (base_dir);
        var file = File.new_build_filename (base_dir, filename);
        var metadata_file = File.new_build_filename (base_dir, filename.replace (".save", ".metadata"));
        try {
            dir.make_directory_with_parents ();
        } catch (Error e) {
            info ("%s", e.message);
        }
        try {
            if (!file.query_exists ()) {
                var os = file.create (FileCreateFlags.NONE);
                os.write_bytes (data);
            } else {
                var ios = file.open_readwrite ();
                ios.output_stream.write_bytes (data);
            }
        } catch (Error e) {
            critical ("%s", e.message);
        }
        var md = new SaverMetadata () {
            name = name,
            uuid = uuid,
            time = new GLib.DateTime.now ().to_unix ()
        };
        size_t len;
        var s = Json.gobject_to_data (md, out len);
        try {
            if (!metadata_file.query_exists ()) {
                var os = metadata_file.create (FileCreateFlags.NONE);
                os.write (s.data);
            } else {
                var ios = metadata_file.open_readwrite ();
                ios.output_stream.write (s.data);
            }
        } catch (Error e) {
            critical ("%s", e.message);
        }
    }
}

public class Conquer.Default.SaveLoader : GLib.Object, Conquer.SaveLoader {
    public Conquer.SavedGame[] enumerate () {
        var ret = new Conquer.SavedGame[0];
        var base_dir = Environment.get_user_data_dir () + "/conquer/saves";
        var dir = File.new_build_filename (base_dir);
        info ("Looking in %s for saved games", base_dir);
        if (!dir.query_exists ()) {
            return ret;
        }
        try {
            var e = dir.enumerate_children ("standard::*", FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
            FileInfo info = null;
            while ((info = e.next_file ()) != null) {
                if (info.get_file_type () == FileType.REGULAR) {
                    var name = info.get_name ();
                    if (name.has_suffix (".metadata")) {
                        size_t len = 0;
                        string contents = "";
                        FileUtils.get_contents (base_dir + "/" + name, out contents, out len);
                        var obj = Json.gobject_from_data (typeof (Conquer.Default.SaverMetadata), contents, (ssize_t) len) as Conquer.Default.SaverMetadata;
                        if (obj == null)
                            continue;
                        var s = new Conquer.Default.SavedGame ();
                        s.name = obj.name;
                        s.time = new GLib.DateTime.from_unix_local (obj.time);
                        s.guid = obj.uuid;
                        ret += s;
                    }
                }
            }
        } catch (Error e) {
            critical ("%s", e.message);
        }
        return ret;
    }
}

public class Conquer.Default.SavedGame : GLib.Object, Conquer.SavedGame {
    public string name { get; set; }
    public DateTime time { get; set; }
    public string guid { get; set; }

    public GameState load(Conquer.Deserializer[] deserializers, Conquer.Strategy[] strategies) {
        var base_dir = Environment.get_user_data_dir () + "/conquer/saves";
        var filename = "%x%x.save".printf (GLib.str_hash (this.name), GLib.str_hash (this.name + this.name));
        info ("%s", filename);
        try {
            var f = File.new_build_filename (base_dir, filename);
            var s = "";
            size_t len = 0;
            FileUtils.get_contents (f.get_path (), out s, out len);
            var fin = f.read ();
            var dis = new DataInputStream (fin);
            var avail = len;
            var bytes = dis.read_bytes (avail);
            info ("Loading %llu bytes from %s", avail, f.get_path ());
            Conquer.Deserializer? des = null;
            foreach (var d in deserializers) {
                if (d.supports_uuid (guid)) {
                    des = d;
                    break;
                }
            }
            assert (des != null);
            return des.deserialize (bytes, strategies);
        } catch (Error e) {
            error ("%s", e.message);
        }
    }
    public Conquer.Saver pair () {
        return new Conquer.Default.Saver ();
    }
}

public class Conquer.Default.Deserializer : GLib.Object, Conquer.Deserializer {
    public Conquer.GameState deserialize (GLib.Bytes state, Conquer.Strategy[] strategies) {
        info ("Restoring gamestate from %d bytes", state.length);
        var g = new Conquer.GameState ();
        var mis = new MemoryInputStream.from_bytes (state);
        var dis = new DataInputStream (mis);
        try {
            if (dis.read_byte () != 0xCC)
                return null;
            if (dis.read_byte () != 0xAA)
                return null;
            if (dis.read_byte () != 0xFF)
                return null;
            if (dis.read_byte () != 0xFF)
                return null;
            if (dis.read_byte () != 0xEE)
                return null;
            if (dis.read_byte () != 0x1)
                return null;
            g.round = (uint)dis.read_uint64 ();
            g.name = this.read_string (dis);
            g.guid = this.read_string (dis);
            g.uuid = this.read_string (dis);
            g.background_image_data = this.read_bytes (dis);
            var n_cities = dis.read_uint64 ();
            var cities = new Conquer.City[n_cities];
            var graph = new Conquer.CityGraph (cities);
            g.cities = graph;
            g.city_list = cities;
            for (var i = 0; i < n_cities; i++) {
                for (var j = 0; j < n_cities; j++) {
                    graph.weights[i,j] = this.read_double (dis);
                }
            }
            var clan_idxs = new uint64[n_cities];
            for (var i = 0; i < n_cities; i++) {
                var city = new Conquer.City ();
                city.growth = this.read_double (dis);
                city.name = this.read_string (dis);
                city.icon_data = this.read_bytes (dis);
                clan_idxs[i] = dis.read_uint64 ();
                city.people = dis.read_uint64 ();
                city.soldiers = dis.read_uint64 ();
                city.x = dis.read_uint64 ();
                city.y = dis.read_uint64 ();
                city.defense = dis.read_uint64 ();
                city.defense_bonus = this.read_double (dis);
                city.defense_level = dis.read_uint64 ();
                foreach (var r in city.upgrades) {
                    dis.read_uint64 ();
                    city.upgrades[r.resource].level = dis.read_uint64 ();
                    city.upgrades[r.resource].production = this.read_double (dis);
                }
                city.index = dis.read_uint64 ();
                cities[i] = city;
            }
            var n_clans = dis.read_uint64 ();
            var clans = new Conquer.Clan[n_clans];
            var clan_uuids = new string[n_clans];
            for (var i = 0; i < n_clans; i++) {
                var clan = new Conquer.Clan ();
                clan.coins = dis.read_uint64 ();
                clan.name = this.read_string (dis);
                clan.color = this.read_string (dis);
                clan.player = dis.read_byte () == 1;
                clan_uuids[i] = this.read_string (dis);
                for (var j = 0; j < Resource.num (); j++) {
                    var n = dis.read_byte ();
                    assert (n == j);
                    clan.resources[j] = this.read_double (dis);
                }
                for (var j = 0; j < Resource.num (); j++) {
                    clan.uses[j] = this.read_double (dis);
                }
                clan.defense_strength = this.read_double (dis);
                clan.attack_strength = this.read_double (dis);
                clan.defense_level = dis.read_uint64 ();
                clan.attack_level = dis.read_uint64 ();
                clan.index = dis.read_uint64 ();
                clans[i] = clan;
            }
            g.clans = clans;
            for (var i = 0; i < n_cities; i++) {
                cities[i].clan = clans[clan_idxs[i]];
            }
            for (var i = 0; i < n_clans; i++) {
                var u = clan_uuids[i];
                foreach (var s in strategies) {
                    if (s.uuid () == u) {
                        var t = s.get_type ();
                        info ("Strategy for %s is a %s", clans[i].name, t.name ());
                        var new_strategy = GLib.Object.new (t, null);
                        clans[i].strategy = (Conquer.Strategy)new_strategy;
                        break;
                    }
                }
            }
            graph.cities = cities;
            g.city_list = cities;
            return g;
        } catch (Error e) {
            error ("%s", e.message);
        }
    }

    private string read_string (DataInputStream dis) throws IOError {
        size_t len = 0;
        var ret = dis.read_upto ("\0", 1, out len);
        dis.read_byte ();
        return ret;
    }
    private Bytes read_bytes (DataInputStream dis) throws Error {
        var n = dis.read_int32 ();
        return dis.read_bytes (n);
    }
    private double read_double (DataInputStream dis) throws IOError {
        uint64 n = dis.read_uint64 ();
        double *d = ((double*)&n);
        return *d;
    }
    public bool supports_uuid (string uuid) {
        return uuid == "84d37b4b-0d3c-4061-a0a5-468c37b125cd";
    }
}

public class Conquer.Default.Serializer : GLib.Object, Conquer.Serializer {
    public GLib.Bytes serialize (Conquer.GameState state) {
        var mos = new GLib.MemoryOutputStream (null);
        var dos = new GLib.DataOutputStream (mos);
        try {
            // Magic number
            dos.put_byte (0xCC);
            dos.put_byte (0xAA);
            dos.put_byte (0xFF);
            dos.put_byte (0xFF);
            dos.put_byte (0xEE);
            // Version
            dos.put_byte (0x1);
            dos.put_uint64 (state.round);
            dos.put_string (state.name);
            dos.put_byte ('\0');
            dos.put_string (state.guid);
            dos.put_byte ('\0');
            dos.put_string (state.uuid);
            dos.put_byte ('\0');
            dos.put_int32 (state.background_image_data.length);
            dos.write_bytes (state.background_image_data);
            var n_cities = state.city_list.length;
            dos.put_uint64 (n_cities);
            for (var i = 0; i < n_cities; i++) {
                for (var j = 0; j < n_cities; j++) {
                    this.write_double (dos, state.cities.weights[i, j]);
                }
            }
            foreach (var c in state.city_list) {
                this.write_double (dos, c.growth);
                dos.put_string (c.name);
                dos.put_byte ('\0');
                dos.put_int32 (c.icon_data.length);
                dos.write_bytes (c.icon_data);
                dos.put_uint64 (c.clan.index);
                dos.put_uint64 (c.people);
                dos.put_uint64 (c.soldiers);
                dos.put_uint64 (c.x);
                dos.put_uint64 (c.y);
                dos.put_uint64 (c.defense);
                this.write_double (dos, c.defense_bonus);
                dos.put_uint64 (c.defense_level);
                foreach (var r in c.upgrades) {
                    dos.put_uint64 ((uint64) (r.resource));
                    dos.put_uint64 (r.level);
                    this.write_double (dos, r.production);
                }
                dos.put_uint64 (c.index);
            }
            dos.put_uint64 (state.clans.length);
            foreach (var c in state.clans) {
                dos.put_uint64 (c.coins);
                dos.put_string (c.name);
                dos.put_byte ('\0');
                dos.put_string (c.color);
                dos.put_byte ('\0');
                dos.put_byte ((uint8) c.player);
                dos.put_string (c.strategy.uuid ());
                dos.put_byte ('\0');
                for (var i = 0; i < Resource.num (); i++) {
                    dos.put_byte ((uint8) i);
                    this.write_double (dos, c.resources[i]);
                }
                for (var i = 0; i < Resource.num (); i++) {
                    this.write_double (dos, c.uses[i]);
                }
                this.write_double (dos, c.defense_strength);
                this.write_double (dos, c.attack_strength);
                dos.put_uint64 (c.defense_level);
                dos.put_uint64 (c.attack_level);
                dos.put_uint64 (c.index);
            }
            dos.close ();
        } catch (Error e) {
            // Shouldn't happen
            error ("%s", e.message);
        }
        return mos.steal_as_bytes ();
    }

    private void write_double (DataOutputStream dos, double d) throws IOError {
        double* v = &d;
        uint64 reint = *((uint64*) v);
        dos.put_uint64 (reint);
    }

    public bool supports_uuid (string uuid) {
        return uuid == "84d37b4b-0d3c-4061-a0a5-468c37b125cd";
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Configuration), typeof (Conquer.Default.SaverConfig));
    obj.register_extension_type (typeof (Conquer.Saver), typeof (Conquer.Default.Saver));
    obj.register_extension_type (typeof (Conquer.Serializer), typeof (Conquer.Default.Serializer));
    obj.register_extension_type (typeof (Conquer.Deserializer), typeof (Conquer.Default.Deserializer));
    obj.register_extension_type (typeof (Conquer.SaveLoader), typeof (Conquer.Default.SaveLoader));
}
