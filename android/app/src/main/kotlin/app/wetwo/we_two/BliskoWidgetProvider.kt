package app.wetwo.we_two

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BliskoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.blisko_widget).apply {
                setTextViewText(R.id.mood, widgetData.getString("mood", "♡"))
                setTextViewText(R.id.mood_label, widgetData.getString("mood_label", ""))
                setTextViewText(R.id.phase, widgetData.getString("phase", "Jeszcze bez wpisu"))
                setTextViewText(R.id.note, widgetData.getString("note", "Otwórz Fąfel Guide, aby się połączyć."))
                setTextViewText(R.id.updated, widgetData.getString("updated", "Dotknij, aby otworzyć"))
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
