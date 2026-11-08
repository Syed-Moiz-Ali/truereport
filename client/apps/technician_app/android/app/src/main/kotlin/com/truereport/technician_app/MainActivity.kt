package com.truereport.technician_app

import android.content.Context
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun attachBaseContext(newBase: Context) {
        val config = Configuration(newBase.resources.configuration)
        // Force fontScale to 1.0 so device font-size settings don't break layout
        config.fontScale = 1.0f
        val fixedContext = newBase.createConfigurationContext(config)
        super.attachBaseContext(fixedContext)
    }

    @Deprecated("Deprecated in Java")
    override fun getResources(): android.content.res.Resources {
        val res = super.getResources()
        val config = res.configuration
        if (config.fontScale != 1.0f) {
            config.fontScale = 1.0f
            @Suppress("DEPRECATION")
            res.updateConfiguration(config, res.displayMetrics)
        }
        return res
    }
}
