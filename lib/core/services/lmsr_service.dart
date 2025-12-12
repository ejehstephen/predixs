import 'dart:math' as math;

class LmsrService {
  /// Robust Log-Sum-Exp helper
  /// ln(exp(x) + exp(y)) = M + ln(exp(x-M) + exp(y-M))
  static double _logSumExp(double x, double y) {
    final maxVal = math.max(x, y);
    return maxVal + math.log(math.exp(x - maxVal) + math.exp(y - maxVal));
  }

  /// Calculates the Cost Function C(q)
  /// C = b * ln(exp(q1/b) + exp(q2/b))
  static double calculateCost({
    required double yesShares,
    required double noShares,
    required double b,
  }) {
    // Robust implementation to prevent exp() overflow
    return b * _logSumExp(yesShares / b, noShares / b);
  }

  /// Estimates shares received for a given trade amount (Buy)
  /// Solves: Amount = C_new - C_old
  static double estimateSharesReceived({
    required double amount,
    required double currentYesShares,
    required double currentNoShares,
    required double b,
    required bool isYesOutcome,
  }) {
    final costOld = calculateCost(
      yesShares: currentYesShares,
      noShares: currentNoShares,
      b: b,
    );

    final costNew = costOld + amount;

    // Stable Inverse Formula: q_new = C_new + b * ln(1 - exp((q_other - C_new)/b))
    try {
      if (isYesOutcome) {
        // q_other is NO shares
        // Term inside log must be > 0.
        // Check liquidity constraint: C_new must be > q_other
        if (costNew <= currentNoShares) return 0.0;

        final exponent = (currentNoShares - costNew) / b;
        final newYes = costNew + b * math.log(1.0 - math.exp(exponent));
        return newYes - currentYesShares;
      } else {
        // q_other is YES shares
        if (costNew <= currentYesShares) return 0.0;

        final exponent = (currentYesShares - costNew) / b;
        final newNo = costNew + b * math.log(1.0 - math.exp(exponent));
        return newNo - currentNoShares;
      }
    } catch (e) {
      // Return 0 on math error (should be caught by logic above but safe guard)
      return 0.0;
    }
  }

  /// Estimates return amount for selling shares
  /// Returns: Refund = C_old - C_new
  static double estimateSellReturn({
    required double sharesToSell,
    required double currentYesShares,
    required double currentNoShares,
    required double b,
    required bool isYesOutcome,
  }) {
    final costOld = calculateCost(
      yesShares: currentYesShares,
      noShares: currentNoShares,
      b: b,
    );

    final double newYes = isYesOutcome
        ? currentYesShares - sharesToSell
        : currentYesShares;
    final double newNo = isYesOutcome
        ? currentNoShares
        : currentNoShares - sharesToSell;

    final costNew = calculateCost(yesShares: newYes, noShares: newNo, b: b);

    return costOld - costNew;
  }

  /// Calculates instantaneous price
  /// P = exp(q/b) / (sum exp)
  /// Robust: exp(q/b - max) / sum(exp(q/b-max))
  static double calculatePrice({
    required double yesShares,
    required double noShares,
    required double b,
    required bool isYesOutcome,
  }) {
    final x = yesShares / b;
    final y = noShares / b;
    final maxVal = math.max(x, y);

    final expYes = math.exp(x - maxVal);
    final expNo = math.exp(y - maxVal);
    final sum = expYes + expNo;

    if (isYesOutcome) {
      return expYes / sum;
    } else {
      return expNo / sum;
    }
  }
}
