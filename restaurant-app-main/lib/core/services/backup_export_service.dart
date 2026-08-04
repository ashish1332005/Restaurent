import '../storage/local_storage.dart';

class BackupExportService {
  BackupExportService._();

  /// Generates CSV report for daily sales and orders history
  static String generateSalesCsvReport() {
    final orders = LocalStorage.getActiveOrders();
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Order ID,Table No,Waiter / Source,Total Amount (INR),Payment Status,Status,Created At');

    for (final order in orders) {
      final id = order['id'] ?? '';
      final tableNo = order['tableNo'] ?? '';
      final waiterName = order['waiterName'] ?? 'Self-Order';
      final total = order['total'] ?? 0;
      final paymentStatus = order['paymentStatus'] ?? 'Unpaid';
      final status = order['status'] ?? 'Pending';
      final createdAt = order['createdAt'] ?? '';

      buffer.writeln('"$id","$tableNo","$waiterName",$total,"$paymentStatus","$status","$createdAt"');
    }

    return buffer.toString();
  }

  /// Generates CSV report for Staff list and credentials summary
  static String generateStaffCsvReport() {
    final staffList = LocalStorage.getStaffList();
    final buffer = StringBuffer();

    buffer.writeln('Staff ID,Name,Phone / Login ID,Role,Shift,Account Status,Created At');

    for (final staff in staffList) {
      final id = staff['id'] ?? '';
      final name = staff['name'] ?? '';
      final phone = staff['phone'] ?? '';
      final role = staff['role'] ?? 'Waiter';
      final shift = staff['shift'] ?? 'Full Day';
      final status = staff['status'] ?? 'Active';
      final createdAt = staff['createdAt'] ?? '';

      buffer.writeln('"$id","$name","$phone","$role","$shift","$status","$createdAt"');
    }

    return buffer.toString();
  }
}
