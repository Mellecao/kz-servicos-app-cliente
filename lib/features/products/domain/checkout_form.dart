import 'package:kz_servicos_app/core/utils/angola_phone.dart';
import 'package:kz_servicos_app/features/products/data/models/product_order.dart';

String? validateDeliveryAddress(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Indique a morada de entrega';
  }
  return null;
}

String? validateContactPhone(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Indique um telemóvel de contacto';
  }
  if (!isValidAngolaPhone(value)) {
    return 'Telemóvel inválido. Ex.: 923 000 001';
  }
  return null;
}

/// Dados do checkout, já validáveis e normalizados para a RPC.
class CheckoutForm {
  const CheckoutForm({
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.reference,
    this.notes,
    this.latitude,
    this.longitude,
  });

  final String address;
  final String phone;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final double? latitude;
  final double? longitude;

  bool get isValid =>
      validateDeliveryAddress(address) == null &&
      validateContactPhone(phone) == null &&
      kProductPaymentMethods.contains(paymentMethod);

  String get cleanAddress => address.trim();
  String? get cleanReference => _blankToNull(reference);
  String? get cleanNotes => _blankToNull(notes);

  /// Gravado sempre em E.164 sem espaços (`+244923000001`).
  String get phoneE164 => toE164Angola(phone);

  static String? _blankToNull(String? value) {
    final v = value?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }
}
