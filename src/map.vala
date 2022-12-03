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
            this.city_actions.update_state.connect (this.one_round);
            this.map_drawing_area.has_tooltip = true;
            this.map_drawing_area.query_tooltip.connect ((x, y, kb, tooltip) => {
                var city = this.find_city (x, y);
                if (city == null)
                    return false;
                tooltip.set_text ("%s (%s)".printf (city.name, city.clan.name));
                return true;
            });
        }
        [GtkChild]
        private unowned Gtk.DrawingArea map_drawing_area;
        [GtkChild]
        private unowned Gtk.Stack city_upgrade;
        [GtkChild]
        private unowned Adw.StatusPage empty_upgrade;
        [GtkChild]
        private unowned Adw.StatusPage empty;
        [GtkChild]
        private unowned Conquer.CityActionScreen city_actions;
        [GtkChild]
        private unowned Conquer.CityInfo city_info;
        [GtkChild]
        private unowned Gtk.Stack right_side;
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
                if (this.start_city != end_city && this.start_city != null && this.start_city.clan.player && end_city != null) {
                    info ("Drag from %s to %s", this.start_city.name, end_city.name);
                    var has_direct_connection = this.game_state.cities.direct_connection (this.start_city, end_city);
                    if (!has_direct_connection) {
                        var dia = new Adw.MessageDialog (((Adw.Application) GLib.Application.get_default ()).active_window, _ ("Error"), _ ("Can't move troops between non-adjacent cities"));
                        dia.add_response ("ok", _ ("_Ok"));
                        dia.response.connect (r => {
                            dia.destroy ();
                        });
                        dia.present ();
                    } else {
                        var is_attack = this.start_city.clan != end_city.clan;
                        var window = new Adw.Window ();
                        window.modal = true;
                        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
                        var bar = new Adw.HeaderBar ();
                        bar.centering_policy = Adw.CenteringPolicy.STRICT;
                        bar.title_widget = new Adw.WindowTitle (is_attack ? _ ("Attack city") : _ ("Move soldiers"), _ ("From %s").printf (this.start_city.name));
                        bar.show_end_title_buttons = false;
                        content.append (bar);
                        var clamp = new Adw.Clamp ();
                        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
                        var max = this.game_state.maximum_number_of_soliders_to_move (start_city, end_city);
                        var scale = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, max == 0 ? 1 : max, 1);
                        scale.sensitive = max != 0;
                        var suggested = new Gtk.Button.with_label (is_attack ? _ ("Attack") : _ ("Move"));
                        suggested.hexpand = true;
                        suggested.sensitive = false;
                        suggested.get_style_context ().add_class ("suggested-action");
                        var abort = new Gtk.Button.with_label (_ ("Cancel"));
                        abort.hexpand = true;
                        scale.value_changed.connect (() => {
                            suggested.sensitive = scale.get_value () != 0;
                        });
                        scale.draw_value = true;
                        scale.digits = 0;
                        var sclamp = new Adw.Clamp ();
                        sclamp.child = scale;
                        sclamp.maximum_size = 330;
                        box.append (sclamp);
                        bar.pack_end (suggested);
                        bar.pack_start (abort);
                        clamp.maximum_size = 360;
                        clamp.child = box;
                        content.append (clamp);
                        abort.clicked.connect (() => {
                            window.destroy ();
                        });
                        var sc = this.start_city;
                        suggested.clicked.connect (() => {
                            if (is_attack) {
                                var result = this.game_state.attack (sc, end_city, (uint64) scale.get_value ());
                                var new_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
                                ((Adw.WindowTitle) bar.title_widget).title = _ ("Result");
                                ((Adw.WindowTitle) bar.title_widget).subtitle = "";
                                var sp = new Adw.StatusPage ();
                                sp.title = result == Conquer.AttackResult.SUCCESS ? _ ("You conquered %s!").printf (end_city.name) : _ ("Your attack failed!");
                                new_box.append (sp);
                                bar.remove (abort);
                                bar.remove (suggested);
                                bar.show_end_title_buttons = true;
                                if (result == Conquer.AttackResult.SUCCESS) {
                                    sp.description = _ ("%llu soldiers survived").printf (end_city.soldiers);
                                }
                                clamp.child = new_box;
                            } else {
                                this.game_state.move (sc, end_city, (uint64) scale.get_value ());
                                window.destroy ();
                            }
                            this.update_visible ();
                        });
                        window.content = content;
                        window.resizable = false;
                        window.present ();
                    }
                }
            }
            this.start_city = null;
            this.start_x = -1;
            this.start_y = -1;
        }

        private void update_visible () {
            Idle.add (() => {
                // Nothing else has to be redrawn currently, as
                // the info and so on are deselected on drag-end.
                this.map_drawing_area.queue_draw ();
                return Source.REMOVE;
            }, Priority.HIGH);
            this.updated ();
        }

        private City ? find_city (double x, double y) {
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
                    this.city_upgrade.visible_child = this.city_actions;
                    this.right_side.visible_child = this.city_info;
                    this.city_info.update (c);
                    this.city_actions.update (this.game_state, this.selected_city);
                    return;
                }
            }
            if (unselect) {
                selected_city = null;
                this.city_upgrade.visible_child = this.empty_upgrade;
                this.right_side.visible_child = this.empty;
                this.map_drawing_area.queue_draw ();
                this.city_info.update (this.selected_city);
                this.city_actions.update (this.game_state, this.selected_city);
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

        internal void one_round () {
            this.map_drawing_area.queue_draw ();
            if (this.selected_city != null && !this.selected_city.clan.player) {
                // Player lost the city
                selected_city = null;
                this.city_upgrade.visible_child = this.empty_upgrade;
                this.right_side.visible_child = this.empty;
            }
            this.city_info.update (this.selected_city);
            this.city_actions.update (this.game_state, this.selected_city);
            this.updated ();
        }

        internal signal void updated ();
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
