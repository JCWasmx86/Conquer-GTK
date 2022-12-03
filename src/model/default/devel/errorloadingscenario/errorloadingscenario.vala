/* errorloadingscenario.vala
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
public class Conquer.Default.Devel.WorkingScenarioLoader : GLib.Object, Conquer.ScenarioLoader {
    public Scenario[] enumerate () throws Conquer.ScenarioLoaderError {
        return new Scenario[1] { new ErrorScenario () };
    }
}

public class Conquer.Default.Devel.ErrorScenario : GLib.Object, Conquer.Scenario {
    public string name { get; set; default = "ErrorScenario"; }
    public Icon? icon { get; set; default = null; }

    public GameState load (Conquer.Strategy[] strategies) throws ScenarioError {
        throw new Conquer.ScenarioError.GENERIC ("[ErrorScenario] Failed to load scenario");
    }
}
public void peas_register_types (TypeModule module) {
    var obj = (Peas.ObjectModule) module;
    if (Environment.get_variable ("CONQUER_DEVEL_ERRORSCENARIO") != null)
        obj.register_extension_type (typeof (Conquer.ScenarioLoader), typeof (Conquer.Default.Devel.WorkingScenarioLoader));
}
