import GLib from 'gi://GLib';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

export default class CenterGhosttyExtension extends Extension {
    enable() {
        this._signals = [];
        this._timeouts = [];
        this._windowCreatedId = global.display.connect('window-created', (_display, window) => {
            this._handleWindow(window);
        });
    }

    disable() {
        if (this._windowCreatedId) {
            global.display.disconnect(this._windowCreatedId);
            this._windowCreatedId = null;
        }
        for (const { obj, id } of this._signals) {
            obj.disconnect(id);
        }
        this._signals = [];
        for (const id of this._timeouts) {
            GLib.source_remove(id);
        }
        this._timeouts = [];
    }

    _handleWindow(window) {
        if (this._isGhostty(window)) {
            this._deferCenter(window);
            return;
        }

        let resolved = false;

        const sigId = window.connect('notify::wm-class', () => {
            if (!resolved && this._isGhostty(window)) {
                resolved = true;
                window.disconnect(sigId);
                this._signals = this._signals.filter(s => s.id !== sigId);
                this._deferCenter(window);
            }
        });
        this._signals.push({ obj: window, id: sigId });

        let attempts = 0;
        const timerId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 50, () => {
            attempts++;
            if (resolved) return GLib.SOURCE_REMOVE;
            if (this._isGhostty(window)) {
                resolved = true;
                try { window.disconnect(sigId); } catch (e) {}
                this._signals = this._signals.filter(s => s.id !== sigId);
                this._deferCenter(window);
                return GLib.SOURCE_REMOVE;
            }
            if (attempts >= 20) return GLib.SOURCE_REMOVE;
            return GLib.SOURCE_CONTINUE;
        });
        this._timeouts.push(timerId);
    }

    _isGhostty(window) {
        const cls = window.get_wm_class();
        return cls && cls.toLowerCase().includes('ghostty');
    }

    _deferCenter(window) {
        let lastWidth = 0;
        let lastHeight = 0;

        const center = () => {
            const frame = window.get_frame_rect();
            if (frame.width === 0 || frame.height === 0) return;
            if (frame.width !== lastWidth || frame.height !== lastHeight) {
                lastWidth = frame.width;
                lastHeight = frame.height;
                this._centerWindow(window);
            }
        };

        const sigId = window.connect('size-changed', () => {
            center();
        });
        this._signals.push({ obj: window, id: sigId });

        center();

        const stopId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 2000, () => {
            this._timeouts = this._timeouts.filter(t => t !== stopId);
            try { window.disconnect(sigId); } catch (e) {}
            this._signals = this._signals.filter(s => s.id !== sigId);
            center();
            return GLib.SOURCE_REMOVE;
        });
        this._timeouts.push(stopId);
    }

    _centerWindow(window) {
        const workArea = window.get_work_area_current_monitor();
        const frame = window.get_frame_rect();
        if (frame.width === 0 || frame.height === 0) return;
        const x = workArea.x + Math.floor((workArea.width - frame.width) / 2);
        const y = workArea.y + Math.floor((workArea.height - frame.height) / 2);
        window.move_frame(true, x, y);
    }
}
