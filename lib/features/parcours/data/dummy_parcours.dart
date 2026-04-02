import '../domain/parcours.dart';

final dummyParcoursList = <Parcours>[
  Parcours(
    id: '1',
    name: 'Cartographie - Centre ville',
    createdAt: DateTime(2025, 3, 1),
    distanceKm: 12.4,
    durationMin: 45,
    totalPoints: 32,
    resolvedCount: 27,
  ),
  Parcours(
    id: '2',
    name: 'Cartographie - Quartier Est',
    createdAt: DateTime(2025, 3, 5),
    distanceKm: 8.7,
    durationMin: 35,
    totalPoints: 21,
    resolvedCount: 9,
  ),
  Parcours(
    id: '3',
    name: 'Cartographie - Zone industrielle',
    createdAt: DateTime(2025, 3, 8),
    distanceKm: 15.2,
    durationMin: 55,
    totalPoints: 40,
    resolvedCount: 40,
  ),
];

