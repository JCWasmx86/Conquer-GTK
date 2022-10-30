/* defaultloader.vala
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
public class Conquer.Default.ScenarioLoader : GLib.Object, Conquer.ScenarioLoader {
    public Scenario[] enumerate() {
        var directories = new string[] {
            Environment.get_user_data_dir() + "/conquer/scenarios",
        };
        foreach (var path in Environment.get_system_data_dirs())
            directories += path + "/conquer/scenarios";
        var ret = new Scenario[0];
        foreach (var path in directories) {
            Dir? dir = null;
            try {
                dir = Dir.open(path, 0);
            } catch (FileError e) {
                info ("%s", e.message);
                continue;
            }
            info("Searching for scenarios in %s", path);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
			    var filepath = Path.build_filename (path, name);
			    if (!FileUtils.test (filepath, FileTest.IS_REGULAR) || !name.has_suffix(".scenario")) {
                    continue;
                }
                var ds = new DefaultScenario(filepath);
                if (!ds.validate()) {
                    continue;
                }
                ret += ds;
            }
        }
        return ret;
    }
}

public void peas_register_types(TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type(typeof (Conquer.ScenarioLoader), typeof (Conquer.Default.ScenarioLoader));
}
