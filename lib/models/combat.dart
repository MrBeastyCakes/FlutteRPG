enum PlayerStance { strike, heavyStrike, defend, readTells, item }

class CombatRound {
  final int roundNumber;
  final PlayerStance chosenStance;
  final int playerDamageDealt;
  final int playerDamageTaken;
  final bool wasCrit;

  const CombatRound({
    required this.roundNumber,
    required this.chosenStance,
    required this.playerDamageDealt,
    required this.playerDamageTaken,
    this.wasCrit = false,
  });
}

class BeastTelegraph {
  final String abilityId;
  final String text;
  final bool reveal;

  const BeastTelegraph({
    required this.abilityId,
    required this.text,
    this.reveal = false,
  });
}
