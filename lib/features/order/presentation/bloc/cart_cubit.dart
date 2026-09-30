import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/menu.dart';
import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/models/user.dart';
import 'package:lelahanoi/core/data/firestore_data_source.dart';
import 'package:lelahanoi/features/auth/data/auth_repository.dart';
import 'package:lelahanoi/features/order/data/cart_storage.dart';

enum CartStatus { loading, ready, submitting, success, failure }

class CartState {
  const CartState({
    required this.status,
    this.items = const [],
    this.quantities = const {},
    this.orderType = OrderType.pickup,
    this.paymentMethod = PaymentMethod.cash,
    this.selectedTime,
    this.user,
    this.error,
    this.submittedTotal,
    this.newSpend,
  });

  final CartStatus status;
  final List<MenuModel> items;
  final Map<String, int> quantities;
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final DateTime? selectedTime;
  final UserModel? user;
  final String? error;
  final int? submittedTotal;
  final int? newSpend;

  int get total => items.fold(
      0, (sum, item) => sum + item.price * (quantities[item.id] ?? 1));

  CartState copyWith({
    CartStatus? status,
    List<MenuModel>? items,
    Map<String, int>? quantities,
    OrderType? orderType,
    PaymentMethod? paymentMethod,
    DateTime? selectedTime,
    UserModel? user,
    String? error,
    bool clearError = false,
    int? submittedTotal,
    int? newSpend,
  }) {
    return CartState(
      status: status ?? this.status,
      items: items ?? this.items,
      quantities: quantities ?? this.quantities,
      orderType: orderType ?? this.orderType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      selectedTime: selectedTime ?? this.selectedTime,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      submittedTotal: submittedTotal ?? this.submittedTotal,
      newSpend: newSpend ?? this.newSpend,
    );
  }
}

class CartCubit extends Cubit<CartState> {
  CartCubit(
      {AuthRepository? authRepository,
      FirestoreDataSource? firestoreService,
      CartStorage? storage})
      : _authRepository = authRepository ?? AuthRepository(),
        _firestoreService = firestoreService ?? FirestoreDataSource(),
        _storage = storage ?? CartStorage(),
        super(const CartState(status: CartStatus.loading));

  final AuthRepository _authRepository;
  final FirestoreDataSource _firestoreService;
  final CartStorage _storage;

  Future<void> load() async {
    final snapshot = await _storage.load();
    final user = await _authRepository.getUserModel();
    emit(CartState(
      status: CartStatus.ready,
      items: snapshot.items,
      quantities: snapshot.quantities,
      user: user,
      selectedTime: DateTime.now().add(const Duration(minutes: 30)),
    ));
  }

  Future<void> add(MenuModel item) async {
    final items = [...state.items];
    final quantities = {...state.quantities};
    if (items.any((current) => current.id == item.id)) {
      quantities[item.id] = (quantities[item.id] ?? 1) + 1;
    } else {
      items.add(item);
      quantities[item.id] = 1;
    }
    emit(state.copyWith(items: items, quantities: quantities));
    await _storage.save(items, quantities);
  }

  Future<void> updateQuantity(int index, int delta) async {
    final items = [...state.items];
    final quantities = {...state.quantities};
    final id = items[index].id;
    final quantity = (quantities[id] ?? 1) + delta;
    if (quantity <= 0) {
      items.removeAt(index);
      quantities.remove(id);
    } else {
      quantities[id] = quantity;
    }
    emit(state.copyWith(items: items, quantities: quantities));
    await _storage.save(items, quantities);
  }

  void setOrderType(OrderType value) => emit(state.copyWith(orderType: value));
  void setPaymentMethod(PaymentMethod value) =>
      emit(state.copyWith(paymentMethod: value));
  void setSelectedTime(DateTime value) =>
      emit(state.copyWith(selectedTime: value));

  Future<void> checkout(
      {required String phone,
      required String address,
      required String email}) async {
    if (state.items.isEmpty || state.status == CartStatus.submitting) return;
    final user = state.user ?? await _authRepository.getUserModel();
    final userId = _authRepository.currentUser?.uid ?? '';
    final spendBeforeOrder = user?.totalMoneySpend ?? 0;
    final total = state.total;
    final userTier =
        UserModel.tierName(UserModel.tierFromSpend(spendBeforeOrder));
    final items = state.items
        .map((item) => OrderItem(
            menuId: item.id,
            menuName: item.name,
            quantity: state.quantities[item.id] ?? 1,
            price: item.price))
        .toList();

    emit(state.copyWith(status: CartStatus.submitting, clearError: true));
    try {
      await _firestoreService.createOrder(
        OrderModel(
          id: '',
          userId: userId,
          userName: user?.name ?? 'Customer',
          userPhone: phone,
          userEmail: email,
          userTier: userTier,
          items: items,
          totalAmount: total,
          earnedPoints: (total / 1000).floor(),
          orderType: state.orderType,
          paymentMethod: state.paymentMethod,
          createdAt: DateTime.now(),
          paymentStatus: PaymentStatus.pending,
          shipAddress: state.orderType == OrderType.ship ? address : null,
          shipTime:
              state.orderType == OrderType.ship ? state.selectedTime : null,
          pickupTime:
              state.orderType == OrderType.pickup ? state.selectedTime : null,
        ),
      );
      await _storage.clear();
      emit(state.copyWith(
          status: CartStatus.success,
          items: const [],
          quantities: const {},
          submittedTotal: total,
          newSpend: spendBeforeOrder + total));
    } catch (error) {
      emit(state.copyWith(status: CartStatus.failure, error: error.toString()));
    }
  }

  void clearResult() =>
      emit(state.copyWith(status: CartStatus.ready, clearError: true));
}
