// TODO Implement this library.
/*class IncomeCategories {
  static const List<String> categories = [
    'Salary',
    'Bonus',
    'Business',
    'Investments',
    'Rental Income',
    'Freelance',
    'Gifts',
    'Refunds',
    'Pension',
    'Allowance',
    'Dividends',
    'Other'
  ];
}*/
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

/*class IncomeCategory {
  static const salary = 'Salary';
  static const business = 'Business';
  static const gift = 'Gift';
  static const other = 'Other';

  static List<String> get all => [salary, business, gift, other];

  static IconData getIcon(String category) {
    switch (category) {
      case salary:
        return FluentIcons.person_24_regular;
      case business:
        return FluentIcons.shopping_bag_24_filled;
      case gift:
        return FluentIcons.gift_24_regular;
      case other:
      default:
        return FluentIcons.star_24_regular;
    }
  }
}*/


class IncomeCategory {
  final String name;
  final IconData icon;

  const IncomeCategory._(this.name, this.icon);

  static const salary = IncomeCategory._('Salary', FluentIcons.person_money_24_regular);
  static const business = IncomeCategory._('Business', FluentIcons.building_bank_24_regular);
  static const gift = IncomeCategory._('Gift', FluentIcons.gift_24_regular);
  static const other = IncomeCategory._('Other', FluentIcons.chat_24_regular);

  static const allCategories = [salary, business, gift, other];

  static List<String> get all => allCategories.map((e) => e.name).toList();

  static IconData getIcon(String categoryName) {
    final cat = allCategories.firstWhere((c) => c.name == categoryName, orElse: () => other);
    return cat.icon;
  }
}

