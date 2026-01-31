import 'package:http/http.dart';

extension ValidResponse on BaseResponse {
  bool get isSuccessfulResponse => statusCode >= 200 && statusCode <= 299;
}
