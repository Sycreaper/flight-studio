import 'dart:math' as math;

/// Centralised aviation unit conversions. Every function is a pure, stateless
/// one-liner so they can be used in any context (UI, domain logic, exporters).
///
/// Conventions:
/// - **Altitude**: feet (`ft`) as canonical; `m`, `FL` (flight level = hundreds of feet).
/// - **Speed**: knots (`kt`) as canonical; `km/h`, `mph`, `Mach` (at ISA sea level).
/// - **Distance**: nautical miles (`nm`) as canonical; `km`, `sm` (statute miles).
/// - **Weight**: kilograms (`kg`) as canonical; `lb`.
/// - **Fuel**: same as weight — `kg` canonical, `lb`, plus `L` / `gal` at jet-A density.

// ── Altitude ────────────────────────────────────────────────────────────────

/// Feet to metres.
double ftToM(double ft) => ft * 0.3048;

/// Metres to feet.
double mToFt(double m) => m / 0.3048;

/// Feet to flight level.
double ftToFL(double ft) => ft / 100;

/// Flight level to feet.
double flToFt(double fl) => fl * 100;

// ── Speed ───────────────────────────────────────────────────────────────────

/// Knots to km/h.
double ktToKmh(double kt) => kt * 1.852;

/// km/h to knots.
double kmhToKt(double kmh) => kmh / 1.852;

/// Knots to miles per hour.
double ktToMph(double kt) => kt * 1.150779;

/// Miles per hour to knots.
double mphToKt(double mph) => mph / 1.150779;

/// Mach number at ISA sea level (speed of sound ≈ 661.5 kt).
double ktToMach(double kt, [double altitudeFt = 0]) {
  // ISA speed of sound decreases with altitude in the troposphere.
  final c = altitudeFt <= 36089
      ? 661.5 * math.sqrt(1 - 0.0000017 * altitudeFt)
      : 573.8; // Stratosphere — constant.
  return kt / c;
}

// ── Distance ────────────────────────────────────────────────────────────────

/// Nautical miles to kilometres.
double nmToKm(double nm) => nm * 1.852;

/// Kilometres to nautical miles.
double kmToNm(double km) => km / 1.852;

/// Nautical miles to statute miles.
double nmToSm(double nm) => nm * 1.150779;

/// Statute miles to nautical miles.
double smToNm(double sm) => sm / 1.150779;

// ── Weight ──────────────────────────────────────────────────────────────────

/// Kilograms to pounds.
double kgToLb(double kg) => kg * 2.20462262185;

/// Pounds to kilograms.
double lbToKg(double lb) => lb / 2.20462262185;

// ── Fuel volume (Jet-A, density ≈ 0.8 kg/L) ────────────────────────────────

/// Kilograms of fuel to litres (specific gravity 0.8).
double kgToLitres(double kg) => kg / 0.8;

/// Litres of fuel to kilograms (specific gravity 0.8).
double litresToKg(double l) => l * 0.8;

/// Kilograms of fuel to US gallons.
double kgToGal(double kg) => kgToLitres(kg) / 3.785411784;

/// US gallons of fuel to kilograms.
double galToKg(double gal) => litresToKg(gal * 3.785411784);

// ── Temperature (ISA) ──────────────────────────────────────────────────────

/// ISA temperature at a given altitude in °C. Troposphere lapse rate: -2°C /
/// 1000 ft. Stratosphere: -56.5°C constant.
double isaTempC(double altitudeFt) {
  return altitudeFt <= 36089 ? 15 - 0.0019812 * altitudeFt : -56.5;
}
