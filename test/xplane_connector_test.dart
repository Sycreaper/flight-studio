// X-Plane connector mapping tests — dataref batches (as the Web API
// pushes them) merged into SimTelemetry with unit conversion, plus the
// unresolved-dataref degradation and probe-failure paths. Uses the fake
// transport from xplane_web_client.dart.

import 'package:flight_studio/data/settings/simulator_install.dart';
import 'package:flight_studio/sim/simulator_connector.dart';
import 'package:flight_studio/sim/xplane/xplane_connector.dart';
import 'package:flight_studio/sim/xplane/xplane_web_client.dart';
import 'package:flutter_test/flutter_test.dart';

SimulatorInstall _install() => SimulatorInstall(
      id: 'sim-1',
      type: SimulatorType.xplane12,
      path: r'D:\X-Plane 12',
    );

void main() {
  test('connects, subscribes and maps an update batch with conversions',
      () async {
    // Manifest names → session ids.
    final known = <String, int>{
      'sim/flightmodel/position/latitude': 101,
      'sim/flightmodel/position/longitude': 102,
      'sim/flightmodel/position/elevation': 103,
      'sim/flightmodel/position/groundspeed': 104,
      'sim/flightmodel/position/vh_ind': 105,
      'sim/flightmodel/position/psi': 106,
      'sim/cockpit2/autopilot/servos_on': 107,
      'sim/cockpit2/autopilot/altitude_dial_ft': 108,
    };
    final transport = FakeXPlaneTransport(known: known);
    final connector = XPlaneConnector(initialTransport: transport);

    final received = <SimTelemetry>[];
    final sub = connector.telemetry.listen(received.add);
    await connector.connect(_install());

    expect(connector.state, SimConnectionState.connected);
    // Every resolved dataref is subscribed exactly once.
    expect(transport.subscribed.toSet(), known.values.toSet());

    transport.emit({
      101: 31.1434,
      102: 121.8052,
      103: 10.0, // metres MSL
      104: 100.0, // m/s
      105: -700.0,
      106: 358.5,
      107: 1,
      108: 12000,
    });
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(1));
    final t = received.single;
    expect(t.latitude, closeTo(31.1434, 1e-9));
    expect(t.longitude, closeTo(121.8052, 1e-9));
    // m → ft, m/s → kt.
    expect(t.altitudeFt, closeTo(32.8084, 1e-3));
    expect(t.groundSpeedKt, closeTo(194.384, 1e-2));
    expect(t.verticalSpeedFpm, -700);
    expect(t.headingDeg, 358.5);
    expect(t.autopilotOn, isTrue);
    expect(t.apAltitudeFt, 12000);
    // Unresolved datarefs stay null, never throw.
    expect(t.indicatedAirspeedKt, isNull);
    expect(t.aircraftName, isNull);

    await sub.cancel();
    await connector.disconnect();
    expect(connector.state, SimConnectionState.disconnected);
  });

  test('a batch that omits unchanged datarefs keeps every field stable',
      () async {
    // The sim pushes ONLY changed values — a batch that carries just the
    // heading must not blank the position/speed fields (the "—" flicker).
    final known = <String, int>{
      'sim/flightmodel/position/latitude': 101,
      'sim/flightmodel/position/longitude': 102,
      'sim/flightmodel/position/elevation': 103,
      'sim/flightmodel/position/psi': 106,
    };
    final transport = FakeXPlaneTransport(known: known);
    final connector = XPlaneConnector(initialTransport: transport);
    final received = <SimTelemetry>[];
    final sub = connector.telemetry.listen(received.add);
    await connector.connect(_install());

    transport.emit({101: 31.0, 102: 121.0, 103: 100.0, 106: 90.0});
    await Future<void>.delayed(Duration.zero);
    // Next batch: ONLY the heading changed.
    transport.emit({106: 91.0});
    await Future<void>.delayed(Duration.zero);

    expect(received, hasLength(2));
    final t = received.last;
    // Position and altitude survive from the accumulated values.
    expect(t.latitude, 31.0);
    expect(t.longitude, 121.0);
    expect(t.altitudeFt, closeTo(328.084, 1e-2));
    expect(t.headingDeg, 91.0);

    await sub.cancel();
    await connector.disconnect();
  });

  test('batches without a position fix emit nothing', () async {
    final known = {'sim/flightmodel/position/elevation': 103};
    final transport = FakeXPlaneTransport(known: known);
    final connector = XPlaneConnector(initialTransport: transport);
    final received = <SimTelemetry>[];
    final sub = connector.telemetry.listen(received.add);
    await connector.connect(_install());

    transport.emit({103: 50.0});
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);

    await sub.cancel();
    await connector.disconnect();
  });

  test('a failed probe rejects connect and marks the state error',
      () async {
    final transport = _FailingTransport();
    final connector = XPlaneConnector(initialTransport: transport);
    await expectLater(connector.connect(_install()), throwsException);
    expect(connector.state, SimConnectionState.error);
  });
}

class _FailingTransport extends FakeXPlaneTransport {
  @override
  Future<String> probe() async => throw Exception('unreachable');
}
