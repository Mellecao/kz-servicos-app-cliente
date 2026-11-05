import 'package:equatable/equatable.dart';

/// Immutable luggage details persisted for a trip.
class TripLuggageData extends Equatable {
  const TripLuggageData({
    required this.type,
    required this.size,
    this.weightKg,
    this.quantity = 1,
  }) : assert(type != '', 'Luggage type must not be empty'),
       assert(
         size == 'small' ||
             size == 'medium' ||
             size == 'large' ||
             size == 'extra_large',
         'Luggage size must be a valid luggage_size value',
       ),
       assert(weightKg == null || weightKg > 0, 'Weight must be positive'),
       assert(quantity > 0, 'Quantity must be positive');

  final String type;
  final String size;
  final double? weightKg;
  final int quantity;

  @override
  List<Object?> get props => [type, size, weightKg, quantity];
}
