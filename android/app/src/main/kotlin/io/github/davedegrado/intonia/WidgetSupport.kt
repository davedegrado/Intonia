package io.github.davedegrado.intonia

import android.content.Context
import android.content.res.Configuration
import android.content.res.Resources
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Chiavi condivise con l'app (HomeWidgetService). */
object WidgetKeys {
  const val LAST_TRAINING_DAY = "intonia_last_training_day"
  const val STREAK = "intonia_streak_at_last_training"
  const val PRECISION_DAYS = "intonia_precision_days"
  const val LANGUAGE = "intonia_language"
}

/**
 * Risorse nella lingua scelta nell'app ([languageCode], salvata da
 * HomeWidgetService); senza indicazioni, quella del dispositivo. Testi:
 * inglese di base (res/values), italiano in res/values-it.
 */
fun localizedResources(context: Context, languageCode: String?): Resources {
  if (languageCode.isNullOrBlank()) {
    return context.resources
  }
  val configuration = Configuration(context.resources.configuration)
  configuration.setLocale(Locale(languageCode))
  return context.createConfigurationContext(configuration).resources
}

/** Giorno locale nel formato `yyyy-MM-dd` usato dall'app. */
fun formatDay(calendar: Calendar): String =
    SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

/** [calendar] spostato di [days] giorni di calendario (negativo = indietro). */
fun addDays(calendar: Calendar, days: Int): Calendar =
    (calendar.clone() as Calendar).apply { add(Calendar.DAY_OF_MONTH, days) }
