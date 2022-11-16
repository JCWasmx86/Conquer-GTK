/* defaultmusic.vala
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
namespace Conquer.Default {
    public class MusicListener : GLib.Object, Conquer.MessageReceiver {
        private GameState? state;
        private bool play;
        private MainLoop? loop;
        private dynamic Gst.Element? music_element;
        private double volume;

        public MusicListener () {
            this.play = true;
            this.state = null;
            this.volume = 1.0;
        }

        public void receive (Conquer.Message msg) {
            if (msg is Conquer.StartGameMessage) {
                this.state = ((Conquer.StartGameMessage) msg).state;
                if (this.play) {
                    this.play = true;
                    new Thread<void> ("music", this.play_music);
                }
            } else if (msg is Conquer.ConfigurationUpdatedMessage) {
                var cc = ((Conquer.ConfigurationUpdatedMessage) msg).config;
                if (cc.id == "sound") {
                    foreach (var ci in cc.configs) {
                        if (ci.id == "play.music") {
                            var val = ((Conquer.BoolConfigurationItem) ci).value;
                            if (val != this.play) {
                                if (val) {
                                    if (this.state != null) {
                                        this.play = true;
                                        new Thread<void> ("music", this.play_music);
                                    }
                                } else if (this.loop != null) {
                                    this.play = false;
                                    this.loop.get_context ().invoke (() => {
                                        if (this.music_element != null)
                                            this.music_element.set_state (Gst.State.NULL);
                                        this.loop.quit ();
                                        return Source.REMOVE;
                                    }, Priority.HIGH);
                                } else {
                                    this.play = false;
                                }
                            }
                        } else if (ci.id == "play.music.volume") {
                            var amount = ((Conquer.IntegerConfigurationItem) ci).value;
                            this.volume = amount / 100.0;
                            if (this.loop != null) {
                                this.loop.get_context ().invoke (() => {
                                    if (this.music_element != null)
                                        this.music_element.volume = this.volume;
                                    return Source.REMOVE;
                                }, Priority.HIGH);
                            } else {
                                if (this.music_element != null)
                                    this.music_element.volume = this.volume;
                            }
                        }
                    }
                }
            } else if (msg is Conquer.ConfigurationLoadedMessage) {
                var cfgs = ((ConfigurationLoadedMessage) msg).config;
                foreach (var c in cfgs) {
                    if (c.id != "sound")
                        continue;
                    foreach (var ci in c.configs) {
                        if (ci.id == "play.music") {
                            this.play = ((Conquer.BoolConfigurationItem) ci).value;
                        } else if (ci.id == "play.music.volume") {
                            this.volume = ((Conquer.IntegerConfigurationItem) ci).value / 100.0;
                        }
                    }
                }
            } else if (msg is Conquer.EndGameMessage) {
                if (this.loop != null) {
                    this.loop.get_context ().invoke (() => {
                        if (this.music_element != null)
                            this.music_element.set_state (Gst.State.NULL);
                        this.loop.quit ();
                        return Source.REMOVE;
                    }, Priority.HIGH);
                }
            }
            // TODO: Handle attack messages where the player
            // is the attacker
        }

        public void play_music () {
            while (this.play) {
                this.loop = new MainLoop ();
                dynamic Gst.Element play = Gst.ElementFactory.make ("playbin", "play");
                play.volume = this.volume;
                this.music_element = play;
                play.uri = this.find_random ();
                info ("URI: %s", play.uri);
                var bus = play.get_bus ();
                bus.add_watch (0, (b, m) => {
                    if (m.type == Gst.MessageType.ERROR) {
                        GLib.Error err;
                        string debug;
                        m.parse_error (out err, out debug);
                        critical ("%s: %s", err.message, debug);
                        loop.quit ();
                    } else if (!this.play) {
                        play.set_state (Gst.State.PAUSED);
                        loop.quit ();
                    } else if (m.type == Gst.MessageType.EOS) {
                        loop.quit ();
                    }
                    return true;
                });
                play.set_state (Gst.State.PLAYING);
                loop.run ();
                play.set_state (Gst.State.NULL);
                this.loop = null;
                this.music_element = null;
                if (!this.play)
                    break;
                var start_time = new DateTime.now_utc ().to_unix ();
                var end_time = start_time + ((ulong) (Random.next_double () * 60 * (1000 * 1000)));
                while (new DateTime.now_utc ().to_unix () <= end_time) {
                    Thread.yield ();
                    if (!this.play) {
                        return;
                    }
                    // Sleep for 0.02 seconds
                    // to avoid bugs that two pieces of music
                    // play concurrently
                    Thread.usleep (20000);
                }
            }
        }

        string find_random () {
            var base_path = "/app/share/conquer/music";
            var paths = new string[0];
            try {
                string directory = base_path;
                Dir dir = Dir.open (directory, 0);
                string? name = null;
                while ((name = dir.read_name ()) != null) {
                    string path = Path.build_filename (directory, name);
                    if (FileUtils.test (path, FileTest.IS_REGULAR) && name.has_prefix ("Battle")) {
                        paths += path;
                    }
                }
            } catch (FileError err) {
                stderr.printf (err.message);
            }
            info ("Found %u music files", paths.length);
            var idx = Random.next_int () % paths.length;
            var file = File.new_for_path (paths[idx]);
            return file.get_uri ();
        }
    }
}

public class Conquer.Default.MusicConfig : GLib.Object, Conquer.Configuration {
    public string name { get; set; }
    public string id { get; set; }
    public GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }
    construct {
        this.name = "Sound";
        this.id = "sound";
        Conquer.ConfigurationItem c = new Conquer.BoolConfigurationItem ("Play music", "play.music", "Whether to play music", true);
        this.configs.append_val ((!) c);
        c = new Conquer.IntegerConfigurationItem ("Music Volume", "play.music.volume", "Volume of the music", 0, 100, 100);
        this.configs.append_val ((!) c);
        c = new Conquer.BoolConfigurationItem ("Play sound effects", "play.soundeffects", "Whether to play soundeffects", true);
        this.configs.append_val ((!) c);
        c = new Conquer.IntegerConfigurationItem ("Sound Effect Volume", "play.soundeffects.volume", "Volume of the soundeffects", 0, 100, 100);
        this.configs.append_val ((!) c);
    }
}

public void peas_register_types (TypeModule module) {
    assert (Thread.supported ());
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Configuration), typeof (Conquer.Default.MusicConfig));
    Conquer.QUEUE.listen (new Conquer.Default.MusicListener ());
}
