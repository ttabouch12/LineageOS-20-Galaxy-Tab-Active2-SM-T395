package org.gta2.perf;

import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;

/** Quick Settings tile: tap to cycle Battery -> Balanced -> Performance -> Max. */
public class ProfileTile extends TileService {
    @Override public void onStartListening() { update(); }
    @Override public void onClick() { Perf.setBase((Perf.baseIndex() + 1) % Perf.PROFILES.length); update(); }
    void update() {
        Tile t = getQsTile(); if (t == null) return;
        int i = Perf.baseIndex();
        t.setLabel("Perf: " + Perf.PROFILES[i][0]);
        t.setState(i >= 2 ? Tile.STATE_ACTIVE : Tile.STATE_INACTIVE);
        t.updateTile();
    }
}
