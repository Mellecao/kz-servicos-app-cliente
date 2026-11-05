import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Mensagem em pt-AO para mostrar ao utilizador. As mensagens das RPC do
/// servidor já vêm em pt-AO (códigos 22023/42501/28000); o resto é genérico,
/// sem expor detalhes técnicos.
String friendlyProductError(Object error, {required String fallback}) {
  if (error is PostgrestException) {
    const userFacing = {'22023', '42501', '28000'};
    if (userFacing.contains(error.code) && error.message.trim().isNotEmpty) {
      return error.message;
    }
  }
  if (error is SocketException) {
    return 'Sem ligação à internet. Verifique a rede e tente novamente.';
  }
  return fallback;
}
