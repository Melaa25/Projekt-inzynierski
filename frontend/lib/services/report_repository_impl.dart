import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'report_remote_data_source.dart';
import 'report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource remoteDataSource;

  ReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, List<int>>> getStockCsv() async {
    try {
      final bytes = await remoteDataSource.downloadStockCsv();
      return Right(bytes);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania raportu.');
    }
  }

  @override
  Future<Either<String, List<int>>> getMovementsCsv({
    DateTime? from,
    DateTime? to,
    String? type,
  }) async {
    try {
      final bytes = await remoteDataSource.downloadMovementsCsv(
        from: from,
        to: to,
        type: type,
      );
      return Right(bytes);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (_) {
      return const Left('Wystąpił nieoczekiwany błąd podczas pobierania raportu.');
    }
  }

  String _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return data['message'] as String;
    }

    return 'Błąd API: ${e.response?.statusCode ?? 'brak kodu'}';
  }
}