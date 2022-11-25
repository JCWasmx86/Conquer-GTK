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
        var filename = "%x%x.save".printf(GLib.str_hash (name), GLib.str_hash (name + name));
        return File.new_build_filename (base_dir, filename).query_exists ();
    }

    public void save (string name, GLib.Bytes data) {
        var base_dir = Environment.get_user_data_dir () + "/conquer/saves";
        var filename = "%x%x.save".printf(GLib.str_hash (name), GLib.str_hash (name + name));
        var dir = File.new_build_filename (base_dir);
        var file = File.new_build_filename (base_dir, filename);
        var metadata_file = File.new_build_filename (base_dir, filename.replace (".save", ".metadata"));
        try {
            dir.make_directory_with_parents ();
        } catch (Error e) {
            info ("%s", e.message);
        }
        try {
            var ios = file.open_readwrite ();
            ios.output_stream.write_bytes (data);
        } catch (Error e) {
            critical ("%s", e.message);
        }
        var md = new SaverMetadata () {
            name = name,
            uuid = "",
            time = new GLib.DateTime.now ().to_unix ()
        };
        size_t len;
        var s = Json.gobject_to_data (md, out len);
        try {
            var ios = metadata_file.open_readwrite ();
            ios.output_stream.write (s.data);
        } catch (Error e) {
            critical ("%s", e.message);
        }
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
            dos.put_string (state.guid);
            dos.put_string (state.uuid);
            dos.put_int32 (state.background_image_data.length);
            dos.write_bytes (state.background_image_data);
            dos.put_uint32 (state.round);
            var n_cities = state.city_list.length;
            dos.put_uint64 (n_cities);
            for (var i = 0; i < n_cities; i++) {
                for (var j = 0; j < n_cities; j++) {
                    this.write_double (dos, state.cities.weights[i,j]);
                }
            }
            foreach (var c in state.city_list) {
                this.write_double (dos, c.growth);
                dos.put_string (c.name);
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
                    dos.put_uint64 ((uint64)(r.resource));
                    dos.put_uint64 (r.level);
                    this.write_double (dos, r.production);
                }
                dos.put_uint64 (c.index);
            }
            dos.put_uint64 (state.clans.length);
            foreach (var c in state.clans) {
                dos.put_uint64 (c.coins);
                dos.put_string (c.name);
                dos.put_string (c.color);
                dos.put_byte ((uint8)c.player);
                dos.put_string (c.strategy.uuid ());
                for (var i = 0; i < Resource.num (); i++) {
                    dos.put_byte ((uint8)i);
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
            mos.close ();
            dos.close ();
        } catch (Error e) {
            // Shouldn't happen
            error ("%s", e.message);
        }
        return mos.steal_as_bytes ();
    }

    private void write_double (DataOutputStream dos, double d) throws IOError {
        double *v = &d;
        uint64 reint = *((uint64*)v);
        dos.put_uint64 (reint);
    }

    public bool supports_uuid (string uuid) {
        return uuid == "84d37b4b-0d3c-4061-a0a5-468c37b125cd";
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Configuration), typeof (Conquer.Default.SaverConfig));
}
