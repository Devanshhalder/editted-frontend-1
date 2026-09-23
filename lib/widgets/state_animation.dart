import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../theme.dart';

enum KarigarKartAnimationState { analyzing, translating, success }

class KarigarKartStateAnimation extends StatelessWidget {
  const KarigarKartStateAnimation({super.key, required this.state, this.size = 120});
  final KarigarKartAnimationState state;
  final double size;

  String get _json {
    switch (state) {
      case KarigarKartAnimationState.translating:
        return _pulseJson(dotCount: 3, color: [0.79, 0.42, 0.26]);
      case KarigarKartAnimationState.success:
        return _checkJson;
      case KarigarKartAnimationState.analyzing:
        return _pulseJson(dotCount: 1, color: [0.12, 0.34, 0.25]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.memory(
      Uint8List.fromList(utf8.encode(_json)),
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: state != KarigarKartAnimationState.success,
      animate: true,
      errorBuilder: (_, __, ___) => Icon(
        state == KarigarKartAnimationState.success ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
        size: size * .55,
        color: state == KarigarKartAnimationState.success ? AppColors.forest : AppColors.clay,
      ),
    );
  }
}

String _pulseJson({required int dotCount, required List<double> color}) {
  final dots = <Map<String, dynamic>>[];
  for (var i = 0; i < dotCount; i++) {
    final x = 100 + (i - (dotCount - 1) / 2) * 42;
    dots.add({
      'ddd': 0,
      'ind': i + 1,
      'ty': 4,
      'nm': 'pulse_$i',
      'ks': {
        'o': {'a': 0, 'k': 100},
        'r': {'a': 0, 'k': 0},
        'p': {'a': 0, 'k': [x, 100, 0]},
        'a': {'a': 0, 'k': [0, 0, 0]},
        's': {'a': 1, 'k': [
          {'t': 0, 's': [72, 72, 100]},
          {'t': 15, 's': [100, 100, 100]},
          {'t': 30, 's': [72, 72, 100]},
        ]},
      },
      'ao': 0,
      'shapes': [
        {'ty': 'el', 'p': {'a': 0, 'k': [0, 0]}, 's': {'a': 0, 'k': [34, 34]}, 'nm': 'dot'},
        {'ty': 'fl', 'c': {'a': 0, 'k': color}, 'o': {'a': 0, 'k': 100}, 'r': 1, 'nm': 'fill'},
        {'ty': 'tr', 'p': {'a': 0, 'k': [0, 0]}, 'a': {'a': 0, 'k': [0, 0]}, 's': {'a': 0, 'k': [100, 100]}, 'r': {'a': 0, 'k': 0}, 'o': {'a': 0, 'k': 100}},
      ],
    });
  }
  return jsonEncode({'v': '5.7.15', 'fr': 30, 'ip': 0, 'op': 30, 'w': 200, 'h': 200, 'nm': 'KarigarKart Pulse', 'ddd': 0, 'assets': [], 'layers': dots});
}

const String _checkJson = '{"v":"5.7.15","fr":30,"ip":0,"op":32,"w":200,"h":200,"nm":"KarigarKart Success","ddd":0,"assets":[],"layers":[{"ddd":0,"ind":1,"ty":4,"nm":"check","ks":{"o":{"a":0,"k":100},"r":{"a":0,"k":0},"p":{"a":0,"k":[100,100,0]},"a":{"a":0,"k":[0,0,0]},"s":{"a":1,"k":[{"t":0,"s":[30,30,100]},{"t":18,"s":[115,115,100]}]}},"ao":0,"shapes":[{"ty":"sh","ks":{"a":0,"k":{"i":[[-35,0],[-10,25],[42,-28]],"o":[[-35,0],[-10,25],[42,-28]],"v":[[-35,0],[-10,25],[42,-28]],"c":false}},"nm":"check path"},{"ty":"st","c":{"a":0,"k":[0.12,0.34,0.25,1]},"o":{"a":0,"k":100},"w":{"a":0,"k":14},"lc":2,"lj":2,"nm":"stroke"},{"ty":"tr","p":{"a":0,"k":[0,0]},"a":{"a":0,"k":[0,0]},"s":{"a":0,"k":[100,100]},"r":{"a":0,"k":0},"o":{"a":0,"k":100}}]}]}';
