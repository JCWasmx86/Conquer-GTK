/* resource.vala
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
public enum Conquer.Resource {
    WHEAT, FISH, WOOD, COAL, MEAT, IRON, TEXTILE, LEATHER, STONE;

    public static Conquer.Resource from_string (string str) {
        switch (str) {
            case "wheat":
                return Resource.WHEAT;
            case "fish":
                return Resource.FISH;
            case "wood":
                return Resource.WOOD;
            case "coal":
                return Resource.COAL;
            case "meat":
                return Resource.MEAT;
            case "iron":
                return Resource.IRON;
            case "textile":
                return Resource.TEXTILE;
            case "leather":
                return Resource.LEATHER;
            case "stone":
                return Resource.STONE;
        }
        return 0;
    }
}
