package com.example.caledoro

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews

class CaledoroWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.caledoro_widget_initial)

            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val secondsRemaining = prefs.getString("secondsRemaining", "0")?.toIntOrNull() ?: 0
            val isWorking = prefs.getString("isWorking", "true")?.toBooleanStrictOrNull() ?: true
            val completedTasks = prefs.getString("completedTasks", "0")?.toIntOrNull() ?: 0

            val minutes = secondsRemaining / 60
            val seconds = secondsRemaining % 60
            views.setTextViewText(R.id.widget_timer, "%02d:%02d".format(minutes, seconds))
            views.setTextViewText(R.id.widget_status, if (isWorking) "Focus" else "Break")
            views.setTextViewText(
                R.id.widget_tasks,
                "$completedTasks quest${if (completedTasks == 1) "" else "s"} done",
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
