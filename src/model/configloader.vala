/* configloader.vala
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
namespace Conquer {
    public interface ConfigLoader : GLib.Object {
        public abstract Conquer.Configuration[]? load ();
        public abstract Conquer.ConfigSaver get_saver ();
    }

    public interface ConfigSaver : GLib.Object {
        public abstract async void save (Configuration[] config);
    }

    public class DefaultConfigSaver : GLib.Object, ConfigSaver {
        public async void save (Configuration[] config) {
            var obj = new Json.Object ();
            obj.set_int_member ("version", 1);
            var configs_object = new Json.Object ();
            foreach (var c in config) {
                var objname = c.id;
                var result = new Json.Object ();
                var arr = new Json.Array ();
                foreach (var cc in c.configs) {
                    var o = new Json.Object ();
                    o.set_string_member ("name", cc.name);
                    o.set_string_member ("id", cc.id);
                    o.set_string_member ("description", cc.description);
                    var id = 0;
                    if (cc is StringConfigurationItem) {
                        o.set_string_member ("value", ((Conquer.StringConfigurationItem)cc).value);
                    } else if (cc is IntegerConfigurationItem) {
                        id = 1;
                        o.set_int_member ("value", ((Conquer.IntegerConfigurationItem)cc).value);
                        o.set_int_member ("min", ((Conquer.IntegerConfigurationItem)cc).min);
                        o.set_int_member ("max", ((Conquer.IntegerConfigurationItem)cc).max);
                    } else if (cc is BoolConfigurationItem) {
                        id = 2;
                        o.set_boolean_member ("value", ((Conquer.BoolConfigurationItem)cc).value);
                    }
                    o.set_int_member ("type", id);
                    var n = new Json.Node (Json.NodeType.OBJECT);
                    n.init_object (o);
                    arr.add_element (n);
                }
                result.set_array_member ("configs", arr);
                configs_object.set_object_member (objname, result);
            }
            obj.set_object_member ("configs", configs_object);
            var n = new Json.Node (Json.NodeType.OBJECT);
            n.init_object (obj);
            var as_string = Json.to_string (n, false) + "\0";
            var dest = new uint8[as_string.data.length];
            ulong dest_length = as_string.data.length;
            ZLib.Utility.compress (dest, ref dest_length, as_string.data);
            var basedir = Environment.get_user_data_dir () + "/conquer/config";
            var file = File.new_for_path (basedir);
            try {
                file.make_directory_with_parents ();
            } catch (Error e) {

            }
            var cfgfile = file.get_child ("maincfg.bin");
            try {
                var ios = cfgfile.replace_readwrite (null, false, GLib.FileCreateFlags.REPLACE_DESTINATION);
                var os = ios.output_stream;
                dest.resize ((int)dest_length);
                os.write (dest);
            } catch (Error e) {
                warning (">> Unable to save config: %s", e.message);
            }
        }
    }

    public class DefaultConfigLoader : GLib.Object, ConfigLoader {
        public Conquer.ConfigSaver get_saver () {
            return new DefaultConfigSaver ();
        }
        public Conquer.Configuration[]? load () {
            var basedir = Environment.get_user_data_dir () + "/conquer/config";
            var file = File.new_for_path (basedir);
            try {
                file.make_directory_with_parents ();
            } catch (Error e) {

            }
            var cfgfile = file.get_child ("maincfg.bin");
            var ret = new Conquer.Configuration[0];
            if (!cfgfile.query_exists ())
                return null;
            try {
                var strm = cfgfile.read ();
                var dis = new DataInputStream (strm);
                var data = new uint8[1024 * 1024 * 8];
                size_t datalen = 0;
                dis.read_all (data, out datalen);
                var decompressedlen = datalen * 100;
                info ("Saved config has %zu bytes, allocating %zu bytes for decompressed data", datalen, decompressedlen);
                var decompressed = new uint8[decompressedlen + 1];
                ZLib.Utility.uncompress (decompressed, ref decompressedlen, data);
                decompressed[decompressedlen] = 0;
                var parser = new Json.Parser ();
                parser.load_from_data ((string)decompressed, (ssize_t)decompressedlen);
                var root = parser.get_root ();
                if (root.get_node_type () != Json.NodeType.OBJECT)
                    return null;
                var obj = root.get_object ();
                if (!obj.has_member ("version"))
                    return null;
                var version = obj.get_int_member ("version");
                if (version != 0x1)
                    return null;
                if (!obj.has_member ("configs"))
                    return null;
                var configs = obj.get_object_member ("configs");
                foreach (var key in configs.get_members ()) {
                    var c = new Conquer.DefaultConfig (key);
                    var cc = configs.get_object_member (key);
                    info ("Loading config %s", key);
                    var array = cc.get_array_member ("configs");
                    foreach (var arr in array.get_elements ()) {
                        var a = arr.get_object ();
                        var type = a.get_int_member ("type");
                        switch (type) {
                            case 0: // String
                                c.append (new Conquer.StringConfigurationItem (a.get_string_member ("name"),
                                                                               a.get_string_member ("id"),
                                                                               a.get_string_member ("description"),
                                                                               a.get_string_member ("value")));
                                break;
                            case 1: // Int
                                c.append (new Conquer.IntegerConfigurationItem (a.get_string_member ("name"),
                                                                                a.get_string_member ("id"),
                                                                                a.get_string_member ("description"),
                                                                                a.get_int_member ("min"),
                                                                                a.get_int_member ("max"),
                                                                                a.get_int_member ("value")));
                                break;
                            case 2: // String
                                c.append (new Conquer.BoolConfigurationItem (a.get_string_member ("name"),
                                                                             a.get_string_member ("id"),
                                                                             a.get_string_member ("description"),
                                                                             a.get_boolean_member ("value")));
                                break;
                            default:
                                error ("Oof: %lld", type);
                        }
                        info ("Loaded config item %s in %s", a.get_string_member ("id"), key);
                    }
                    ret += c;
                }
            } catch (Error e) {
                critical ("%s", e.message);
                return null;
            }
            return ret;
        }
    }

    public class DefaultConfig : GLib.Object, Conquer.Configuration {
        public string name { get; set; }
        public string id { get; set; }
        public GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }

        public DefaultConfig (string key) {
            this.name = "Ignore me";
            this.id = key;
        }
        public void append (Conquer.ConfigurationItem c) {
            this.configs.append_val ((!)c);
        }
    }
}
