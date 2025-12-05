import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class ExpenseCategory {
  static const foodDining = 'Food & Dining';
  static const transportation = 'Transportation';
  static const shopping = 'Shopping';
  static const entertainment = 'Entertainment';
  static const billsUtilities = 'Bills & Utilities';
  static const healthcare = 'Healthcare';
  static const education = 'Education';
  static const travel = 'Travel';
  static const personalCare = 'Personal Care';
  static const other = 'Other';

  static const List<String> all = [
    foodDining,
    transportation,
    shopping,
    entertainment,
    billsUtilities,
    healthcare,
    education,
    travel,
    personalCare,
    other,
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case foodDining:
        return FluentIcons.food_24_regular;
      case transportation:
        return FluentIcons.vehicle_car_24_regular;
      case shopping:
        return FluentIcons.cart_24_regular;
      case entertainment:
        return FluentIcons.video_24_regular;
      case billsUtilities:
        return FluentIcons.receipt_24_regular;
      case healthcare:
        return FluentIcons.heart_pulse_24_regular;
      case education:
        return FluentIcons.book_24_regular;
      case travel:
        return FluentIcons.airplane_24_regular;
      case personalCare:
        return FluentIcons.person_24_regular;
      case other:
      default:
        return FluentIcons.more_horizontal_24_regular;
    }
  }
}

class PaymentMethod {
  static const cash = 'cash';
  static const card = 'card';
  static const bankTransfer = 'bank_transfer';

  static const List<String> all = [cash, card, bankTransfer];

  static String getLabel(String method) {
    switch (method) {
      case cash:
        return 'Cash';
      case card:
        return 'Card';
      case bankTransfer:
        return 'Bank Transfer';
      default:
        return method;
    }
  }

  static IconData getIcon(String method) {
    switch (method) {
      case cash:
        return FluentIcons.money_24_regular;
      case card:
        return FluentIcons.payment_24_regular;
      case bankTransfer:
        return FluentIcons.building_bank_24_regular;
      default:
        return FluentIcons.wallet_24_regular;
    }
  }
}
