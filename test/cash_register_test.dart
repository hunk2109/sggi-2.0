import 'package:flutter_test/flutter_test.dart';
import 'package:sggi_desktop/features/cash_register/models/cash_register_model.dart';
import 'package:sggi_desktop/features/cash_register/models/sale_history_model.dart';
import 'package:sggi_desktop/features/cash_register/models/shift_payment_model.dart';
import 'package:sggi_desktop/features/cash_register/providers/cash_register_provider.dart';

void main() {
  group('CashRegisterModel Tests', () {
    test('Parsea correctamente JSON con valores numéricos y calcula balances', () {
      final json = {
        'id': 'reg_123',
        'userId': 'user_01',
        'openingAmount': '1500.00',
        'closingAmount': '2000.00',
        'expectedClosure': '2000.00',
        'difference': '0.00',
        'isOpen': true,
        'createdAt': '2026-11-02T08:00:00.000Z',
      };

      final model = CashRegisterModel.fromJson(json);

      expect(model.id, 'reg_123');
      expect(model.openingAmount, 1500.0);
      expect(model.closingAmount, 2000.0);
      expect(model.expectedClosure, 2000.0);
      expect(model.difference, 0.0);
      expect(model.isOpen, isTrue);
      expect(model.isBalanced, isTrue);
      expect(model.hasSurplus, isFalse);
      expect(model.hasDeficit, isFalse);
    });

    test('Identifica sobrantes y faltantes de caja', () {
      final surplusModel = CashRegisterModel.fromJson({
        'id': 'reg_surplus',
        'userId': 'u1',
        'openingAmount': 1000,
        'difference': 150.50,
        'isOpen': false,
      });

      expect(surplusModel.hasSurplus, isTrue);
      expect(surplusModel.hasDeficit, isFalse);
      expect(surplusModel.isBalanced, isFalse);

      final deficitModel = CashRegisterModel.fromJson({
        'id': 'reg_deficit',
        'userId': 'u1',
        'openingAmount': 1000,
        'difference': -200.00,
        'isOpen': false,
      });

      expect(deficitModel.hasDeficit, isTrue);
      expect(deficitModel.hasSurplus, isFalse);
      expect(deficitModel.isBalanced, isFalse);
    });
  });

  group('CashTransactionModel Tests', () {
    test('Distingue correctamente entre ingresos y egresos de caja', () {
      final inTx = CashTransactionModel.fromJson({
        'id': 'tx_1',
        'cashRegisterId': 'reg_1',
        'type': 'in',
        'amount': '500',
        'concept': 'Cambio adicional',
      });

      expect(inTx.isIn, isTrue);
      expect(inTx.isOut, isFalse);
      expect(inTx.amount, 500.0);

      final outTx = CashTransactionModel.fromJson({
        'id': 'tx_2',
        'cashRegisterId': 'reg_1',
        'type': 'out',
        'amount': '250',
        'concept': 'Pago de hielo',
      });

      expect(outTx.isOut, isTrue);
      expect(outTx.isIn, isFalse);
      expect(outTx.amount, 250.0);
    });
  });

  group('CashRegisterState Business Logic Calculations', () {
    test('Calcula totales de ventas, pagos y dinero en gaveta excluyendo canceladas', () {
      final register = CashRegisterModel(
        id: 'reg_live',
        userId: 'cashier_1',
        openingAmount: 2000.0,
        isOpen: true,
        createdAt: DateTime.now(),
      );

      final sales = [
        SaleHistoryModel(
          id: 's1',
          totalAmount: 300.0,
          discount: 0.0,
          paymentMethod: 'cash',
          status: 'completed',
          customerName: 'Juan Perez',
          createdAt: DateTime.now(),
          items: [],
        ),
        SaleHistoryModel(
          id: 's2',
          totalAmount: 500.0,
          discount: 0.0,
          paymentMethod: 'card',
          status: 'completed',
          customerName: 'Maria Lopez',
          createdAt: DateTime.now(),
          items: [],
        ),
        SaleHistoryModel(
          id: 's3',
          totalAmount: 1000.0,
          discount: 0.0,
          paymentMethod: 'cash',
          status: 'cancelled', // Esta no debe sumarse
          customerName: 'Venta Anulada',
          createdAt: DateTime.now(),
          items: [],
        ),
      ];

      final payments = <ShiftPaymentModel>[
        ShiftPaymentModel(
          id: 'p1',
          amount: 1500.0,
          paymentMethod: 'cash',
          paymentType: 'membership',
          status: 'completed',
          concept: 'Mensual VIP',
          memberName: 'Carlos Gomez',
          memberCode: 'M001',
          createdAt: DateTime.now(),
        ),
        ShiftPaymentModel(
          id: 'p2',
          amount: 2000.0,
          paymentMethod: 'transfer',
          paymentType: 'membership',
          status: 'completed',
          concept: 'Anual',
          memberName: 'Ana Soto',
          memberCode: 'M002',
          createdAt: DateTime.now(),
        ),
      ];

      final transactions = [
        CashTransactionModel(
          id: 'tx1',
          cashRegisterId: 'reg_live',
          type: 'out',
          amount: 200.0,
          concept: 'Gasto limpieza',
          createdAt: DateTime.now(),
        ),
        CashTransactionModel(
          id: 'tx2',
          cashRegisterId: 'reg_live',
          type: 'in',
          amount: 100.0,
          concept: 'Aporte sencillo',
          createdAt: DateTime.now(),
        ),
      ];

      final state = CashRegisterState(
        currentRegister: register,
        sales: sales,
        payments: payments,
        currentTransactions: transactions,
      );

      expect(state.isRegisterOpen, isTrue);
      // Ventas: 300 (cash) + 500 (card) = 800 (1000 cancelled ignored)
      expect(state.totalSalesAmount, 800.0);
      expect(state.cashSalesAmount, 300.0);
      expect(state.completedSalesCount, 2);

      // Membresías: 1500 (cash) + 2000 (transfer) = 3500
      expect(state.totalPaymentsAmount, 3500.0);
      expect(state.cashPaymentsAmount, 1500.0);
      expect(state.completedPaymentsCount, 2);

      // Egresos / Ingresos
      expect(state.totalWithdrawals, 200.0);
      expect(state.totalInflows, 100.0);

      // Total facturado turno = ventas (800) + cobros membresías (3500) + otros ingresos (100) = 4400
      expect(state.totalShiftRevenue, 4400.0);

      // Total efectivo en gaveta = fondo (2000) + ventas efectivo (300) + membresías efectivo (1500) + ingresos (100) - retiros (200) = 3700.0
      expect(state.totalCashInDrawer, 3700.0);
    });

    test('Retorna cero en totales calculados si no hay caja abierta', () {
      final closedState = CashRegisterState(
        currentRegister: null,
        sales: [
          SaleHistoryModel(
            id: 's1',
            totalAmount: 300.0,
            discount: 0.0,
            paymentMethod: 'cash',
            status: 'completed',
            customerName: 'Juan',
            createdAt: DateTime.now(),
            items: [],
          ),
        ],
      );

      expect(closedState.isRegisterOpen, isFalse);
      expect(closedState.totalSalesAmount, 0.0);
      expect(closedState.cashSalesAmount, 0.0);
      expect(closedState.completedSalesCount, 0);
      expect(closedState.totalPaymentsAmount, 0.0);
      expect(closedState.totalCashInDrawer, 0.0);
    });
  });
}
