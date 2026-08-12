import 'package:dio/dio.dart';

abstract class ReportRemoteDataSource {
  Future<List<int>> downloadStockCsv();

  Future<List<int>> downloadMovementsCsv({
    DateTime? from,
    DateTime? to,
    String? type,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final Dio dio;

  ReportRemoteDataSourceImpl(this.dio);

  @override
  Future<List<int>> downloadStockCsv() async {
    final response = await dio.get<List<int>>(
      '/reports/stock',
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? [];
  }

  @override
  Future<List<int>> downloadMovementsCsv({
    DateTime? from,
    DateTime? to,
    String? type,
  }) async {
    final response = await dio.get<List<int>>(
      '/reports/movements',
      queryParameters: {
        if (from != null) 'from': _formatDate(from),
        if (to != null) 'to': _formatDate(to),
        if (type != null) 'type': type,
      },
      options: Options(responseType: ResponseType.bytes),
    );

    return response.data ?? [];
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}