import 'package:dio/dio.dart';
import 'package:internal_network/internal_network.dart';

import 'constants.dart';

Dio get appDioClient => AppClient(
  options: BaseOptions(headers: {'X-Api-Key': ApiConstants.apiKey}),
);