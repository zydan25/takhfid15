package com.altakhfeedalsh.app;

import android.os.Bundle;

import com.getcapacitor.BridgeActivity;

/**
 * Native back handling:
 * - When an internal Takhfid view/modal is open, JavaScript handles the back action.
 * - On the store home screen, JavaScript returns false and the Activity exits normally.
 */
public class MainActivity extends BridgeActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onBackPressed() {
        if (bridge == null || bridge.getWebView() == null) {
            super.onBackPressed();
            return;
        }

        bridge.getWebView().evaluateJavascript(
            "(function(){try{return window.__takhfidHandleNativeBack ? window.__takhfidHandleNativeBack() : false;}catch(e){return false;}})();",
            value -> {
                boolean handled = "true".equals(value);
                if (!handled) {
                    runOnUiThread(() -> MainActivity.super.onBackPressed());
                }
            }
        );
    }
}
