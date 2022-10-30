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

    public void load () {
    }
}

private class Conquer.DefaultMetadata : Object {
    public string name { get; set; }
    public int version { get; set; default = 1; }
}
