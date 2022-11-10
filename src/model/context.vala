/* context.vala
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
    public class Context {
        private Peas.Engine engine;
        private Peas.ExtensionSet scenario_loaders;
        private Peas.ExtensionSet strategies;
        private Peas.ExtensionSet configs;

        public Context() {
            this.engine = Peas.Engine.get_default ();
            this.scenario_loaders = new Peas.ExtensionSet(this.engine, typeof (Conquer.ScenarioLoader));
            this.strategies = new Peas.ExtensionSet(this.engine, typeof (Conquer.Strategy));
            this.configs = new Peas.ExtensionSet(this.engine, typeof (Conquer.Configuration));
            this.engine.enable_loader("python3");
            this.add_search_path(Environment.get_user_data_dir () + "/conquer/plugins");
            this.add_search_path(Environment.get_home_dir () + "/.local/share/conquer/plugins");
            foreach(var path in Environment.get_system_data_dirs())
                this.add_search_path(path + "/conquer/plugins");
            foreach (var plugin in this.engine.get_plugin_list())
				this.engine.try_load_plugin(plugin);
            foreach (var s in this.engine.loaded_plugins)
                info ("Loaded plugin %s", s);
            Conquer.MessageQueue.init ();
            Conquer.QUEUE.emit (new InitMessage ());
        }
        private void add_search_path(string p) {
            info ("Adding search path %s", p);
            this.engine.add_search_path (p, null);
        }

        public Scenario[] find_scenarios () {
            var ret = new Scenario[0];
            scenario_loaders.@foreach((s, info, exten) => {
               var found = ((Conquer.ScenarioLoader)exten).enumerate ();
                foreach (var sc in found)
                    ret += sc;
            });
            info ("Found %u scenarios", ret.length);
            return ret;
        }

        public Strategy[] find_strategies () {
            var ret = new Strategy[0];
            strategies.@foreach((s, info, exten) => {
               ret += (Strategy)exten;
            });
            info ("Found %u strategies", ret.length);
            return ret;
        }
        public Configuration[] find_configs () {
            var ret = new Configuration[0];
            configs.@foreach((s, info, exten) => {
               ret += (Conquer.Configuration)exten;
            });
            info ("Found %u configs", ret.length);
            return ret;
        }
    }
}
