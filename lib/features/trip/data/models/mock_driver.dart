class MockDriver {
  final String id;
  final String name;
  final String initials;
  final String carModel;
  final String carColor;
  final String licensePlate;
  final double rating;
  final String description;
  final String rg;
  final DateTime birthDate;
  final List<String> extras;
  final String? driverNote;

  const MockDriver({
    required this.id,
    required this.name,
    required this.initials,
    required this.carModel,
    required this.carColor,
    required this.licensePlate,
    required this.rating,
    required this.description,
    required this.rg,
    required this.birthDate,
    required this.extras,
    this.driverNote,
  });

  static final List<MockDriver> samples = [
    MockDriver(
      id: 'driver_1',
      name: 'João Silva',
      initials: 'JS',
      carModel: 'Toyota Corolla 2023',
      carColor: 'Preto',
      licensePlate: 'ABC-1D23',
      rating: 4.8,
      description:
          'Motorista profissional há 8 anos. Especialista em '
          'viagens longas e atendimento executivo. Veículo sempre '
          'limpo e higienizado.',
      rg: '12.345.678-9',
      birthDate: DateTime(1985, 3, 15),
      extras: ['Wi-Fi', 'Água mineral', 'Carregador USB'],
      driverNote: 'Consigo ir ao seu encontro daqui 10min somente, pois estou em outra corrida.',
    ),
    MockDriver(
      id: 'driver_2',
      name: 'Maria Santos',
      initials: 'MS',
      carModel: 'Honda Civic 2024',
      carColor: 'Branco',
      licensePlate: 'DEF-4E56',
      rating: 4.9,
      description:
          'Atenciosa e pontual. Mais de 2.000 corridas realizadas '
          'com nota máxima. Experiência com transporte de crianças '
          'e cadeirinha disponível.',
      rg: '98.765.432-1',
      birthDate: DateTime(1990, 7, 22),
      extras: ['Wi-Fi', 'Cadeirinha infantil', 'Balas e snacks'],
      driverNote: 'Estou disponível imediatamente! Posso buscar na porta.',
    ),
    MockDriver(
      id: 'driver_3',
      name: 'Carlos Oliveira',
      initials: 'CO',
      carModel: 'VW Virtus 2023',
      carColor: 'Cinza',
      licensePlate: 'GHI-7F89',
      rating: 4.7,
      description:
          'Ex-motorista de táxi com 15 anos de experiência. '
          'Conhece todas as rotas da cidade. Sempre disponível '
          'para bate-papo ou silêncio, como preferir.',
      rg: '45.678.901-2',
      birthDate: DateTime(1978, 11, 5),
      extras: ['Ar condicionado premium', 'Água mineral', 'Revistas'],
    ),
  ];
}
