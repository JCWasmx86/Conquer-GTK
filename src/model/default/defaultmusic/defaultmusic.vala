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
        private GameState state;
        private bool play;

        public MusicListener () {
            this.play = false;
        }
        public void receive (Conquer.Message msg) {
            if (msg is Conquer.StartGameMessage) {
                this.state = ((Conquer.StartGameMessage)msg).state;
                this.play = true;
                new Thread<void> ("music", this.play_music);
            }
            // TODO: Handle attack messages where the player
            // is the attacker
        }
        public void play_music () {
            while (this.play) {
                var loop = new MainLoop ();
                dynamic Gst.Element play = Gst.ElementFactory.make ("playbin", "play");
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
                // Sleep max 60 seconds, so it sounds better
                Thread.usleep ((ulong)(Random.next_double () * 60 * (1000 * 1000)));
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
    public GLib.Array<Conquer.ConfigurationItem> configs { get; set; default = new GLib.Array<Conquer.ConfigurationItem> (); }
    construct {
        this.name = "Sound";
        Conquer.ConfigurationItem c = new Conquer.BoolConfigurationItem ("Play music", "play.music", "Whether to play music", true);
        this.configs.append_val ((!)c);
        c = new Conquer.IntegerConfigurationItem ("Music Volume", "play.music.volume", "Volume of the music", 0, 100, 100);
        this.configs.append_val ((!)c);
        c = new Conquer.BoolConfigurationItem ("Play sound effects", "play.soundeffects", "Whether to play soundeffects", true);
        this.configs.append_val ((!)c);
        c = new Conquer.IntegerConfigurationItem ("Sound Effect Volume", "play.soundeffects.volume", "Volume of the soundeffects", 0, 100, 100);
        this.configs.append_val ((!)c);
    }
}

public void peas_register_types (TypeModule module) {
    assert (Thread.supported ());
    var obj = (Peas.ObjectModule) module;
    obj.register_extension_type (typeof (Conquer.Configuration), typeof (Conquer.Default.MusicConfig));
    Conquer.QUEUE.listen (new Conquer.Default.MusicListener ());
}
