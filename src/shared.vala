/* shared.vala
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
public class Conquer.Shared {
    public static string from_resource (Conquer.Resource r) {
        switch (r) {
        case Conquer.Resource.WOOD:
            return _ ("Wood");
        case Conquer.Resource.FOOD:
            return _ ("Food");
        case Conquer.Resource.IRON:
            return _ ("Iron");
        case Conquer.Resource.STONE:
            return _ ("Stone");
        }
        assert_not_reached ();
    }
}
