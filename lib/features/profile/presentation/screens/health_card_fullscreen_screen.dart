import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_sizes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../data/models/health_card.dart';
import '../widgets/health_card_widgets.dart';

// Mekânda gösterilmek üzere büyütülmüş kart.
class HealthCardFullscreenScreen extends StatelessWidget {
  const HealthCardFullscreenScreen({super.key, required this.card});

  final HealthCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: IconButton(
                  icon: const Icon(Icons.close, color: kOnSurface),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.screenPaddingH,
                    0,
                    AppSizes.screenPaddingH,
                    AppSizes.lg,
                  ),
                  child: HealthCardView(card: card, scale: 1.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
