package com.biblepic.bible_pic

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Shows the pre-rendered verse image Flutter saved for today (or the fixed verse). */
class VerseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val fixed = widgetData.getString("mode", "votd") == "fixed"
        val imageKey = if (fixed) "img_fixed" else "img_$today"
        val verseKey = if (fixed) "verse_fixed" else "verse_$today"
        val imagePath = widgetData.getString(imageKey, null)
        val verseId = widgetData.getString(verseKey, null)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.verse_widget)
            val bitmap = imagePath?.let { BitmapFactory.decodeFile(it) }
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
                views.setViewVisibility(R.id.widget_empty, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            }
            val uri = Uri.parse("biblepic://verse/${verseId ?: ""}")
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, uri),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
