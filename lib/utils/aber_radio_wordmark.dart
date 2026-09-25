import 'package:flutter/material.dart';

class AberRadioWordmark extends StatelessWidget {
  const AberRadioWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'PublicSans',
      fontSize: 36,
      fontWeight: FontWeight.w900,
      height: 1,
      letterSpacing: -2.2,
    );

    return Semantics(
      label: 'Aber Radio',
      image: true,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'ABER',
                  style: style.copyWith(color: const Color(0xFF0B4C3B)),
                ),
                TextSpan(
                  text: 'RADIO',
                  style: style.copyWith(color: const Color(0xFFF7B500)),
                ),
              ],
            ),
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
