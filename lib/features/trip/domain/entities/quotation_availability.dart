enum QuotationAvailability { available, unavailable }

QuotationAvailability computeQuotationAvailability({
  required DateTime nowInSp,
  required String adminOverride,
  int startHour = 7,
  int endHour = 20,
}) {
  if (adminOverride == 'force_enabled') return QuotationAvailability.available;
  if (adminOverride == 'force_disabled') return QuotationAvailability.unavailable;
  final h = nowInSp.hour;
  return (h >= startHour && h < endHour)
      ? QuotationAvailability.available
      : QuotationAvailability.unavailable;
}
