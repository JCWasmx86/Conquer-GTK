/* map.vala
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
    [GtkTemplate (ui = "/io/github/jcwasmx86/Conquer/map.ui")]
    public class Map : Gtk.Box {
        construct {
            this.map_drawing_area.set_draw_func (this.draw_func);
            var gc = new Gtk.GestureClick ();
            gc.released.connect (on_click);
            this.map_drawing_area.add_controller (gc);
            var gd = new Gtk.GestureDrag ();
            gd.drag_begin.connect (this.drag_begin);
            gd.drag_end.connect (this.drag_end);
            this.map_drawing_area.add_controller (gd);
        }
        [GtkChild]
        private unowned Gtk.DrawingArea map_drawing_area;
        private Conquer.GameState game_state;
        private Conquer.City? selected_city;
        private Conquer.City? start_city;
        private double start_x;
        private double start_y;

        internal void update (Conquer.GameState g) {
            this.game_state = g;
            this.selected_city = null;
            this.start_city = null;
            this.start_x = -1;
            this.start_y = -1;
            var map_surface = new BytesReader (g.background_image_data).read_surface ();
            this.map_drawing_area.set_content_height (map_surface.get_height ());
            this.map_drawing_area.set_content_width (map_surface.get_width ());
            info ("Setting area to size %dx%d", map_surface.get_width (), map_surface.get_height ());
        }

        private void drag_begin (double start_x, double start_y) {
            this.start_city = this.find_city (start_x, start_y);
            this.start_x = start_x;
            this.start_y = start_y;
        }

        private void drag_end (double offset_x, double offset_y) {
            if (this.start_city != null) {
                var end_city = this.find_city (start_x + offset_x, start_y + offset_y);
                if (this.start_city != end_city)
                    info ("Drag from %s to %s", this.start_city.name, end_city.name);
            }
            this.start_city = null;
            this.start_x = -1;
            this.start_y = -1;
        }

        private City? find_city (double x, double y) {
            foreach (var c in this.game_state.city_list) {
                var map_surface = new BytesReader (c.icon_data).read_surface ();
                var x_matches = x <= c.x + map_surface.get_width () + 20 && x >= c.x - 20;
                var y_matches = y <= c.y + map_surface.get_height () + 20 && y >= c.y - 20;
                if (x_matches && y_matches)
                    return c;
            }
            return null;
        }

        private void on_click (int n, double x, double y) {
            var unselect = false;
            foreach (var c in this.game_state.city_list) {
                var map_surface = new BytesReader (c.icon_data).read_surface ();
                var x_matches = x <= c.x + map_surface.get_width () + 20 && x >= c.x - 20;
                var y_matches = y <= c.y + map_surface.get_height () + 20 && y >= c.y - 20;
                if (x_matches && y_matches) {
                    if (!c.clan.player) {
                        unselect = true;
                        continue;
                    }
                    selected_city = c;
                    this.map_drawing_area.queue_draw ();
                    return;
                }
            }
            if (unselect) {
                selected_city = null;
                this.map_drawing_area.queue_draw ();
            }
        }

        void draw_func (Gtk.DrawingArea area, Cairo.Context cr, int w, int h) {
            var map_surface = new BytesReader (this.game_state.background_image_data).read_surface ();
            cr.set_operator (Cairo.Operator.OVER);
            cr.set_source_surface (map_surface, 0, 0);
            cr.paint ();
            var len = this.game_state.city_list.length;
            for (var i = 0; i < len; i++) {
                for (var j = 0; j < len; j++) {
                    if (this.game_state.cities.weights[i, j] > 0) {
                        var c1 = this.game_state.city_list[i];
                        var s1 = new BytesReader (c1.icon_data).read_surface ();
                        var c2 = this.game_state.city_list[j];
                        var s2 = new BytesReader (c2.icon_data).read_surface ();
                        var c1_x = c1.x + s1.get_width () / 2;
                        var c2_x = c2.x + s2.get_width () / 2;
                        var c1_y = c1.y + s1.get_height () / 2;
                        var c2_y = c2.y + s2.get_height () / 2;
                        cr.set_line_width (2);
                        cr.set_source_rgba (1, 1, 1, 0.3);
                        cr.move_to (c1_x, c1_y);
                        cr.line_to (c2_x, c2_y);
                        cr.stroke ();
                    }
                }
            }
            foreach (var c in this.game_state.city_list) {
                var surface = new BytesReader (c.icon_data).read_surface ();
                cr.set_operator (Cairo.Operator.OVER);
                cr.set_source_surface (surface, c.x, c.y);
                cr.paint ();
                var height = 12;
                if (c != this.selected_city)
                    cr.set_source_rgb (1.0, 1.0, 1.0);
                else
                    cr.set_source_rgb (0.5, 0.5, 0.1);
                cr.set_operator (Cairo.Operator.OVER);
                cr.rectangle (c.x, c.y + surface.get_height (), surface.get_width (), height);
                cr.fill ();
                var color = Gdk.RGBA ();
                color.parse (c.clan.color);
                cr.set_source_rgb (color.red, color.green, color.blue);
                cr.set_operator (Cairo.Operator.OVER);
                cr.rectangle (c.x + 2, c.y + surface.get_height () + 2, surface.get_width () - 4, height - 4);
                cr.fill ();
            }
        }
    }

    private class BytesReader {
        private uint offset;
        private Bytes bytes;

        public BytesReader (Bytes b) {
            this.bytes = b;
            this.offset = 0;
        }

        private Cairo.Status read (uchar[] data) {
            if (offset + data.length <= this.bytes.length) {
                var d = bytes.get_data ();
                for (var i = 0; i < data.length; i++)
                    data[i] = d[this.offset + i];
                this.offset += data.length;
                return Cairo.Status.SUCCESS;
            }
            return Cairo.Status.READ_ERROR;
        }

        public Cairo.ImageSurface read_surface () {
            return new Cairo.ImageSurface.from_png_stream (this.read);
        }
    }
}
