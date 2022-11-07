/* diagram.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/diagram.ui")]
    public class Diagram : Gtk.Box {
        construct {
            this.area.set_draw_func (this.draw_func);
            this.area.set_size_request (800, 800);
        }
        [GtkChild]
        internal unowned Gtk.Label title;
        [GtkChild]
        private unowned Gtk.DrawingArea area;
        [GtkChild]
        private unowned Gtk.FlowBox box;
        internal ValueCalculator calc;
        internal Conquer.GameState state;

        internal void init (GameState g) {
            while (true) {
                var w = this.box.get_child_at_index (0);
                if (w == null)
                    break;
                this.box.remove (w);
            }
            foreach (var clan in g.clans) {
                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
                var da = new Gtk.DrawingArea ();
                da.set_size_request (32, 32);
                da.hexpand = false;
                da.vexpand = false;
                da.set_draw_func ((a, c, w, h) => {
                    var color = Gdk.RGBA ();
                    color.parse (clan.color);
                    c.set_source_rgb (color.red, color.green, color.blue);
                    c.rectangle (0, 0, 32, 32);
                    c.fill ();
                });
                box.append (da);
                box.append (new Gtk.Label (clan.name));
                this.box.append (box);
            }
        }
        void draw_func (Gtk.DrawingArea area, Cairo.Context cr, int w, int h) {
            var clans = this.state.clans;
            var values = new double[clans.length];
            var total = 0.0;
            for (var i = 0; i < clans.length; i++) {
                values[i] = this.calc (this.state, clans[i]);
                total += values[i];
            }
            var degrees = new double[clans.length];
            for (var i = 0; i < clans.length; i++) {
                degrees[i] = (values[i] / total) * 360.0;
            }
            var real_degrees = new double[clans.length];
            for (var i = 0; i < clans.length; i++) {
                if (i == 0)
                    real_degrees[i] = degrees[i];
                else
                    real_degrees[i] = degrees[i] + real_degrees[i - 1];
            }
            var radius = (w * 0.8) / 2;
            for (var i = clans.length - 1; i >= 0; i--) {
                cr.move_to (w / 2.0, h / 2.0);
                var color = Gdk.RGBA ();
                color.parse (clans[i].color);
                cr.set_source_rgb (color.red, color.green, color.blue);
                cr.arc (w / 2.0, h / 2.0, radius, 0, real_degrees[i] * (Math.PI / 180.0));
                cr.fill ();
            }
        }

        internal void update () {
            Idle.add (() => {
                this.area.queue_draw ();
                return Source.REMOVE;
            }, Priority.HIGH);
        }
    }

    public delegate double ValueCalculator (GameState g, Clan clan);
}
