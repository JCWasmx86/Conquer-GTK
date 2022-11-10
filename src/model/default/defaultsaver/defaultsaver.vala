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
    public GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }
    construct {
        this.name = "Settings";
        var c = new Conquer.StringConfigurationItem ("Storage location for saved games", "storage.location", "Where to store the saved games.", Environment.get_user_data_dir () + "/conquer/saves");
        this.configs.append_val ((!) c);
    }
}

public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Configuration), typeof (Conquer.Default.SaverConfig));
}
