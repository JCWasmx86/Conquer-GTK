/* databaselistener.vala
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
public class Conquer.DatabaseListener : GLib.Object, Conquer.MessageReceiver {
    private Sqlite.Database db;
    public DatabaseListener() {
        var dir = Environment.get_user_data_dir () + "/conquer";
        try {
            File.new_for_path (dir).make_directory_with_parents ();
        } catch (Error e) {
            info ("%s", e.message);
        }
        var ec = Sqlite.Database.open (dir + "/stats.db", out this.db);
        if (ec != Sqlite.OK) {
            error ("Can't open database: %d: %s", db.errcode (), db.errmsg ());
        }
        try {
            var init_script = GLib.resources_lookup_data ("/io/github/jcwasmx86/Conquer/init_db.sql", GLib.ResourceLookupFlags.NONE);
            string errmsg;
            ec = this.db.exec ((string)init_script.get_data (), null, out errmsg);
            if (ec != Sqlite.OK) {
                error ("Error: %s", errmsg);
            }
        } catch (Error e) {
            error ("%s", e.message);
        }
    }
    public void receive (Conquer.Message msg) {
        if (msg is Conquer.StartGameMessage) {
            var sgm = (Conquer.StartGameMessage)msg;
            var state = sgm.state;
        } else if (msg is Conquer.EndGameMessage) {
            var egm = (Conquer.EndGameMessage)msg;
            var sql = "INSERT INTO result (rounds, result) VALUES (%lu, %lu);".printf (egm.state.round, egm.result);
            string errmsg;
            var ec = this.db.exec (sql, null, out errmsg);
            if (ec != Sqlite.OK) {
                critical ("Error: %s", errmsg);
            }
        }
    }
}
