package io.github.davedegrado.intonia

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Resources
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * Widget della serie: la mascotte di Intonia tra luci e nuvole, i giorni di
 * fila in grande e un messaggio. I dati arrivano dall'app
 * (HomeWidgetService); lo stato del giorno è ricalcolato qui, così il widget
 * resta corretto anche ad app chiusa. Stessa logica di WidgetView
 * (lib/features/home_widget/domain/widget_streak.dart).
 */
class IntoniaWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val content =
        WidgetContent.of(
            lastTrainingDay = widgetData.getString(WidgetKeys.LAST_TRAINING_DAY, null),
            streakAtLastTraining =
                widgetData.getString(WidgetKeys.STREAK, null)?.toIntOrNull() ?: 0,
            now = Calendar.getInstance(),
        )
    val res = localizedResources(context, widgetData.getString(WidgetKeys.LANGUAGE, null))
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_intonia)
      bind(res, views, content)
      views.setOnClickPendingIntent(
          R.id.widget_root,
          HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
      )
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun bind(res: Resources, views: RemoteViews, content: WidgetContent) {
    val message =
        res.getString(
            when (content.status) {
              WidgetStatus.TRAINED_TODAY -> R.string.widget_message_trained
              WidgetStatus.FIRST_DAY -> R.string.widget_message_first_day
              WidgetStatus.KEEP_STREAK -> R.string.widget_message_keep_streak
              WidgetStatus.START -> R.string.widget_message_start
            },
        )
    val celebrating =
        content.status == WidgetStatus.TRAINED_TODAY || content.status == WidgetStatus.FIRST_DAY
    views.setImageViewResource(
        R.id.widget_scene,
        if (celebrating) R.drawable.widget_scene_happy else R.drawable.widget_scene_invite,
    )
    views.setTextViewText(R.id.widget_streak_number, content.streak.toString())
    views.setTextViewText(
        R.id.widget_streak_label,
        res.getQuantityString(R.plurals.widget_streak_label, content.streak),
    )
    views.setTextViewText(R.id.widget_message, message)
    views.setContentDescription(
        R.id.widget_streak_text,
        res.getQuantityString(R.plurals.widget_streak_title, content.streak, content.streak) +
            ". " +
            message,
    )
  }
}

enum class WidgetStatus {
  TRAINED_TODAY,
  FIRST_DAY,
  KEEP_STREAK,
  START,
}

data class WidgetContent(
    val status: WidgetStatus,
    /** Giorni di fila mostrati (0 se la serie non è in corso). */
    val streak: Int,
) {
  companion object {
    fun of(lastTrainingDay: String?, streakAtLastTraining: Int, now: Calendar): WidgetContent {
      val today = formatDay(now)
      val yesterday = formatDay(addDays(now, -1))
      val alive =
          streakAtLastTraining > 0 && (lastTrainingDay == today || lastTrainingDay == yesterday)
      if (!alive) {
        return WidgetContent(WidgetStatus.START, 0)
      }
      val status =
          when {
            lastTrainingDay == yesterday -> WidgetStatus.KEEP_STREAK
            streakAtLastTraining == 1 -> WidgetStatus.FIRST_DAY
            else -> WidgetStatus.TRAINED_TODAY
          }
      return WidgetContent(status, streakAtLastTraining)
    }
  }
}
