import 'package:flutter/material.dart';

/// Formats [dateTime] (converted to local time) as a short time-of-day
/// string (e.g. "3:45 PM") using Flutter's own localizations, so the app
/// doesn't need an `intl` dependency just for this.
String formatCacheTime(BuildContext context, DateTime dateTime) {
  return TimeOfDay.fromDateTime(dateTime.toLocal()).format(context);
}
