class MockChatMessage {
  final String id;
  final String text;
  final bool isFromUser;
  final DateTime sentAt;

  const MockChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.sentAt,
  });
}

class MockConversation {
  final String id;
  final String tripId;
  final String origin;
  final String destination;
  final List<MockChatMessage> messages;
  final DateTime lastMessageAt;
  final int unreadCount;

  const MockConversation({
    required this.id,
    required this.tripId,
    required this.origin,
    required this.destination,
    required this.messages,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  static final List<MockConversation> samples = [
    MockConversation(
      id: 'conv_1',
      tripId: 'sched_1',
      origin: 'Rua Augusta, 1200',
      destination: 'Aeroporto de Guarulhos',
      lastMessageAt: DateTime(2026, 4, 15, 8, 10),
      unreadCount: 2,
      messages: [
        MockChatMessage(
          id: 'msg_1',
          text: 'Olá! A sua viagem foi confirmada para amanhã às 08:30.',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 14, 18, 0),
        ),
        MockChatMessage(
          id: 'msg_2',
          text: 'Obrigada! O motorista vai me encontrar na portaria?',
          isFromUser: true,
          sentAt: DateTime(2026, 4, 14, 18, 5),
        ),
        MockChatMessage(
          id: 'msg_3',
          text:
              'Sim! O motorista João Silva estará na portaria do prédio. '
              'Ele vai entrar em contato 10 minutos antes.',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 14, 18, 7),
        ),
        MockChatMessage(
          id: 'msg_4',
          text: 'Perfeito, obrigada!',
          isFromUser: true,
          sentAt: DateTime(2026, 4, 14, 18, 8),
        ),
        MockChatMessage(
          id: 'msg_5',
          text: 'Motorista a caminho! Previsão de chegada: 08:20.',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 15, 8, 10),
        ),
      ],
    ),
    MockConversation(
      id: 'conv_2',
      tripId: 'sched_2',
      origin: 'Av. Paulista, 1578',
      destination: 'Shopping Eldorado',
      lastMessageAt: DateTime(2026, 4, 14, 10, 30),
      unreadCount: 1,
      messages: [
        MockChatMessage(
          id: 'msg_6',
          text:
              'O seu pedido de viagem foi recebido. '
              'Estamos buscando um motorista.',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 14, 10, 0),
        ),
        MockChatMessage(
          id: 'msg_7',
          text: 'Quanto tempo demora pra confirmar?',
          isFromUser: true,
          sentAt: DateTime(2026, 4, 14, 10, 15),
        ),
        MockChatMessage(
          id: 'msg_8',
          text:
              'Normalmente confirmamos em até 2 horas. '
              'Fique tranquilo(a) que entraremos em contato!',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 14, 10, 30),
        ),
      ],
    ),
    MockConversation(
      id: 'conv_3',
      tripId: 'hist_1',
      origin: 'Rua Oscar Freire, 379',
      destination: 'Av. Faria Lima, 3477',
      lastMessageAt: DateTime(2026, 4, 10, 19, 0),
      unreadCount: 0,
      messages: [
        MockChatMessage(
          id: 'msg_9',
          text: 'A sua viagem foi concluída! Obrigado por viajar connosco.',
          isFromUser: false,
          sentAt: DateTime(2026, 4, 10, 19, 0),
        ),
      ],
    ),
  ];
}
