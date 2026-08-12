import 'package:dartz/dartz.dart';

abstract class ReportRepository {
  Future<Either<String, List<int>>> getStockCsv();

  Future<Either<String, List<int>>> getMovementsCsv({
    DateTime? from,
    DateTime? to,
    String? type,
  });
}