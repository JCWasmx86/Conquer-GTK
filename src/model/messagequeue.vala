/* messagequeue.vala
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
    public static MessageQueue? QUEUE;

    public class MessageQueue {
        private GLib.List<MessageReceiver> listeners = new List<MessageReceiver>();
        public static void init () {
            if (QUEUE == null)
                QUEUE = new MessageQueue ();
        }

        public MessageQueue () {
        }

        public void listen (MessageReceiver receiver) {
            this.listeners.append (receiver);
        }

        public void emit (Conquer.Message msg) {
            info ("Emitting message of type %s to %llu listeners", msg.get_type ().name (), this.listeners.length ());
            foreach (var m in this.listeners)
                m.receive (msg);
        }
    }

    public interface MessageReceiver : Object {
        public abstract void receive (Conquer.Message msg);
    }
}
