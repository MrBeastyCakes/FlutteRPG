enum CoastWeather { calm, seaFog, stormSwell }

class CoastWeatherState {
  final CoastWeather current;
  final DateTime nextRollAt;
  const CoastWeatherState({required this.current, required this.nextRollAt});
}
