import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lelahanoi/core/models/order.dart';
import 'package:lelahanoi/core/models/user.dart';
import 'package:lelahanoi/features/order/data/order_repository.dart';

enum OrderStatusState { loading, ready, failure }

class OrderState {
  const OrderState(
      {required this.status,
      this.orders = const [],
      this.users = const [],
      this.error});

  final OrderStatusState status;
  final List<OrderModel> orders;
  final List<UserModel> users;
  final String? error;
}

class OrderCubit extends Cubit<OrderState> {
  OrderCubit({String? userId, OrderRepository? repository})
      : _repository = repository ?? OrderRepository(),
        super(const OrderState(status: OrderStatusState.loading)) {
    _ordersSubscription = _repository.watchOrders(userId: userId).listen(
          (orders) => emit(OrderState(
              status: OrderStatusState.ready,
              orders: orders,
              users: state.users)),
          onError: (error) => emit(OrderState(
              status: OrderStatusState.failure, error: error.toString())),
        );
    if (userId == null) {
      _usersSubscription = _repository.watchUsers().listen(
            (users) => emit(OrderState(
                status: OrderStatusState.ready,
                orders: state.orders,
                users: users)),
            onError: (error) => emit(OrderState(
                status: OrderStatusState.failure, error: error.toString())),
          );
    }
  }

  final OrderRepository _repository;
  StreamSubscription<List<OrderModel>>? _ordersSubscription;
  StreamSubscription<List<UserModel>>? _usersSubscription;

  Future<void> completeOrder(String id, PaymentMethod method) =>
      _repository.completeOrder(id, method);

  @override
  Future<void> close() async {
    await _ordersSubscription?.cancel();
    await _usersSubscription?.cancel();
    return super.close();
  }
}
