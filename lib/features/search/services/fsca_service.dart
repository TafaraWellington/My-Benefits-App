import 'package:dio/dio.dart';
import '../models/fsca_models.dart';

abstract class IFscaService {
  Future<List<BenefitResult>> searchBenefits({
    required EnquirerDetails enquirer,
    required TargetDetails target,
  });
}

class FscaService implements IFscaService {
  final Dio _dio = Dio();

  @override
  Future<List<BenefitResult>> searchBenefits({
    required EnquirerDetails enquirer,
    required TargetDetails target,
  }) async {
    // In a real implementation, this would involve:
    // 1. Initializing session on https://www.fsca.co.za/Unclaimed-Benefits-Search/
    // 2. Submitting Step 1 data
    // 3. Submitting Step 2 data
    // 4. Parsing the HTML result table
    
    // For now, we simulate the network delay
    await Future.delayed(const Duration(seconds: 3));

    // Simulate a successful search result for demonstration
    return [
      BenefitResult(
        fundName: 'Metal Industries Provident Fund',
        administrator: 'NBC Holdings (Pty) Ltd',
        contactDetails: '010 205 6000 | info@nbc.co.za',
        status: 'Match Found',
      ),
      BenefitResult(
        fundName: 'Private Security Sector Provident Fund',
        administrator: 'Salt Employee Benefits',
        contactDetails: '011 492 1533 | claims@psspf.org.za',
        status: 'Match Found',
      ),
    ];
  }
}

class MockFscaService implements IFscaService {
  @override
  Future<List<BenefitResult>> searchBenefits({
    required EnquirerDetails enquirer,
    required TargetDetails target,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    if (target.surname.toLowerCase() == 'none') {
      return [];
    }
    return [
      BenefitResult(
        fundName: 'Example Pension Fund',
        administrator: 'Example Admin Services',
        contactDetails: '0800 123 456 | help@example.co.za',
        status: 'Potential Match',
      ),
    ];
  }
}
