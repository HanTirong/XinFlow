import 'package:xinflow/features/categories/domain/category.dart';
import 'package:xinflow/features/transactions/domain/transaction_entry.dart';

abstract final class DefaultCategoryIds {
  static const food = 'builtin.expense.food';
  static const shopping = 'builtin.expense.shopping';
  static const housing = 'builtin.expense.housing';
  static const transport = 'builtin.expense.transport';
  static const digital = 'builtin.expense.digital';
  static const saving = 'builtin.saving';
  static const investment = 'builtin.investment';
  static const travel = 'builtin.expense.travel';
  static const fixedExpense = 'builtin.expense.fixed';
  static const other = 'builtin.expense.other';
}

abstract final class DefaultCategories {
  static final List<Category> values = List.unmodifiable([
    ..._topLevel,
    ..._children,
  ]);

  static final List<Category> _topLevel = [
    Category(
      id: DefaultCategoryIds.food,
      name: '饮食',
      flowType: FlowType.expense,
      iconKey: 'restaurant',
      colorKey: 'coral',
      sortOrder: 10,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.shopping,
      name: '购物',
      flowType: FlowType.expense,
      iconKey: 'shopping_bag',
      colorKey: 'pink',
      sortOrder: 20,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.housing,
      name: '住房',
      flowType: FlowType.expense,
      iconKey: 'home',
      colorKey: 'blue',
      sortOrder: 30,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.transport,
      name: '交通',
      flowType: FlowType.expense,
      iconKey: 'directions_bus',
      colorKey: 'green',
      sortOrder: 40,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.digital,
      name: '数字服务',
      flowType: FlowType.expense,
      iconKey: 'laptop',
      colorKey: 'purple',
      sortOrder: 50,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.saving,
      name: '存款',
      flowType: FlowType.saving,
      iconKey: 'savings',
      colorKey: 'amber',
      sortOrder: 60,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.investment,
      name: '理财',
      flowType: FlowType.investment,
      iconKey: 'bar_chart',
      colorKey: 'cyan',
      sortOrder: 70,
      isSystem: true,
      showOnHome: true,
    ),
    Category(
      id: DefaultCategoryIds.travel,
      name: '旅行',
      flowType: FlowType.expense,
      iconKey: 'flight_takeoff',
      colorKey: 'indigo',
      sortOrder: 75,
      isSystem: true,
    ),
    Category(
      id: DefaultCategoryIds.fixedExpense,
      name: '固定开支',
      flowType: FlowType.expense,
      iconKey: 'calendar_month',
      colorKey: 'orange',
      sortOrder: 77,
      isSystem: true,
    ),
    Category(
      id: DefaultCategoryIds.other,
      name: '其他',
      flowType: FlowType.expense,
      iconKey: 'more_horiz',
      colorKey: 'neutral',
      sortOrder: 80,
      isSystem: true,
      showOnHome: true,
    ),
  ];

  static final List<Category> _children = [
    ..._expenseChildren(DefaultCategoryIds.food, 'food', const [
      '外食',
      '买菜',
      '零食饮料',
    ]),
    ..._expenseChildren(DefaultCategoryIds.shopping, 'shopping', const [
      '超市购物',
      '电商购物',
      '生活用品',
    ]),
    ..._expenseChildren(DefaultCategoryIds.housing, 'housing', const [
      '房租',
      '水电燃气',
      '物业维修',
    ]),
    ..._expenseChildren(DefaultCategoryIds.transport, 'transport', const [
      '公交地铁',
      '打车',
      '加油停车',
    ]),
    ..._expenseChildren(DefaultCategoryIds.digital, 'digital', const [
      'AI 软件',
      'App 订阅',
      '影音会员',
    ]),
    ..._childrenFor(
      parentId: DefaultCategoryIds.saving,
      keyPrefix: 'saving',
      names: const ['活期存款', '定期存款', '备用金'],
      flowType: FlowType.saving,
    ),
    ..._childrenFor(
      parentId: DefaultCategoryIds.investment,
      keyPrefix: 'investment',
      names: const ['基金', '股票', '其他理财'],
      flowType: FlowType.investment,
    ),
    ..._expenseChildren(DefaultCategoryIds.travel, 'travel', const [
      '酒店住宿',
      '机票／火车票',
      '当地交通',
      '景点门票',
      '旅行餐饮',
      '签证／保险',
      '旅行购物',
      '其他旅行支出',
    ]),
    ..._expenseChildren(DefaultCategoryIds.other, 'other', const [
      '医疗',
      '教育',
      '人情',
      '未分类',
    ]),
  ];

  static List<Category> _expenseChildren(
    String parentId,
    String keyPrefix,
    List<String> names,
  ) => _childrenFor(
    parentId: parentId,
    keyPrefix: keyPrefix,
    names: names,
    flowType: FlowType.expense,
  );

  static List<Category> _childrenFor({
    required String parentId,
    required String keyPrefix,
    required List<String> names,
    required FlowType flowType,
  }) => [
    for (var index = 0; index < names.length; index++)
      Category(
        id: 'builtin.$keyPrefix.${index + 1}',
        parentId: parentId,
        name: names[index],
        flowType: flowType,
        iconKey: keyPrefix,
        colorKey: 'neutral',
        sortOrder: (index + 1) * 10,
        isSystem: true,
      ),
  ];
}
