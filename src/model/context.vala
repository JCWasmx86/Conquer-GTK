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
        public Conquer.ConfigLoader config_loader;
        private Configuration[] ? restored_configs;
        private Peas.Engine engine;
        private Peas.ExtensionSet scenario_loaders;
        private Peas.ExtensionSet save_loaders;
        private Peas.ExtensionSet strategies;
        private Peas.ExtensionSet savers;
        private Peas.ExtensionSet serializers;
        private Peas.ExtensionSet deserializers;
        private Peas.ExtensionSet configs;

        public Context (Conquer.ConfigLoader loader) {
            this.engine = Peas.Engine.get_default ();
            this.scenario_loaders = new Peas.ExtensionSet (this.engine, typeof (Conquer.ScenarioLoader));
            this.save_loaders = new Peas.ExtensionSet (this.engine, typeof (Conquer.SaveLoader));
            this.strategies = new Peas.ExtensionSet (this.engine, typeof (Conquer.Strategy));
            this.configs = new Peas.ExtensionSet (this.engine, typeof (Conquer.Configuration));
            this.savers = new Peas.ExtensionSet (this.engine, typeof (Conquer.Saver));
            this.serializers = new Peas.ExtensionSet (this.engine, typeof (Conquer.Serializer));
            this.deserializers = new Peas.ExtensionSet (this.engine, typeof (Conquer.Deserializer));
            this.engine.enable_loader ("python3");
            this.add_search_path (Environment.get_user_data_dir () + "/conquer/plugins");
            this.add_search_path (Environment.get_home_dir () + "/.local/share/conquer/plugins");
            foreach (var path in Environment.get_system_data_dirs ())
                this.add_search_path (path + "/conquer/plugins");
            foreach (var plugin in this.engine.get_plugin_list ())
                this.engine.try_load_plugin (plugin);
            foreach (var s in this.engine.loaded_plugins)
                info ("Loaded plugin %s", s);
            this.config_loader = loader;
            Conquer.MessageQueue.init ();
            Conquer.QUEUE.emit (new InitMessage ());
        }

        public void init () {
            var loaded = this.config_loader.load ();
            if (loaded != null) {
                Conquer.QUEUE.emit (new ConfigurationLoadedMessage (loaded));
            }
        }

        private void add_search_path (string p) {
            info ("Adding search path %s", p);
            this.engine.add_search_path (p, null);
        }

        public Scenario[] find_scenarios () {
            var ret = new Scenario[0];
            scenario_loaders.@foreach ((s, info, exten) => {
                try {
                    var found = ((Conquer.ScenarioLoader) exten).enumerate ();
                    foreach (var sc in found)
                        ret += sc;
                } catch (ScenarioLoaderError e) {
                    this.emit_scenario_loader_error (e);
                }
            });
            info ("Found %u scenarios", ret.length);
            return ret;
        }

        public SavedGame[] find_saved_games () {
            var ret = new SavedGame[0];
            save_loaders.@foreach ((s, info, exten) => {
                var found = ((Conquer.SaveLoader) exten).enumerate ();
                foreach (var sc in found)
                    ret += sc;
            });
            info ("Found %u saved games", ret.length);
            return ret;
        }

        public Strategy[] find_strategies () {
            var ret = new Strategy[0];
            strategies.@foreach ((s, info, exten) => {
                ret += (Strategy) exten;
            });
            info ("Found %u strategies", ret.length);
            return ret;
        }

        public Saver[] find_savers () {
            var ret = new Saver[0];
            savers.@foreach ((s, info, exten) => {
                ret += (Saver) exten;
            });
            info ("Found %u savers", ret.length);
            return ret;
        }

        public Serializer[] find_serializers () {
            var ret = new Serializer[0];
            serializers.@foreach ((s, info, exten) => {
                ret += (Serializer) exten;
            });
            info ("Found %u serializers", ret.length);
            return ret;
        }

        public Deserializer[] find_deserializers () {
            var ret = new Deserializer[0];
            deserializers.@foreach ((s, info, exten) => {
                ret += (Deserializer) exten;
            });
            info ("Found %u deserializers", ret.length);
            return ret;
        }

        public Configuration[] find_configs () {
            var ret = new Configuration[0];
            this.restored_configs = this.config_loader.load ();
            configs.@foreach ((s, info, exten) => {
                var c = (Conquer.Configuration) exten;
                ret += c;
            });
            if (restored_configs != null) {
                info ("Patching configs to match the saved ones");
                // TODO: This is beyond stupid
                foreach (var r in ret) {
                    foreach (var c in restored_configs) {
                        if (r.id == c.id) {
                            for (var i = 0; i < r.configs.length; i++) {
                                for (var j = 0; j < c.configs.length; j++) {
                                    if (r.configs.index (i).id == c.configs.index(j).id) {
                                        r.configs.index (i).assign (c.configs.index(j));
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                this.restored_configs = ret;
            }
            info ("Found %u configs", ret.length);
            return ret;
        }

        public void emit_changed (Configuration changed) {
            Conquer.QUEUE.emit (new Conquer.ConfigurationUpdatedMessage (changed));
            if (this.restored_configs != null) {
                for (var i = 0; i < this.restored_configs.length; i++)
                    if (this.restored_configs[i].id == changed.id) {
                        this.restored_configs[i] = changed;
                        break;
                    }
                this.config_loader.get_saver ().save (this.restored_configs);
            }
        }

        public void save (Conquer.GameState state, string name, Conquer.Saver saver) {
            foreach (var ser in this.find_serializers ()) {
                if (ser.supports_uuid (state.guid)) {
                    var data = ser.serialize (state);
                    info ("Used serializer %s to serialize gamestate (%d bytes)", ser.get_type ().name (), data.length);
                    saver.save (name, state.guid, data);
                    return;
                }
            }
        }

        public signal void emit_scenario_loader_error (Conquer.ScenarioLoaderError e);
    }
}
