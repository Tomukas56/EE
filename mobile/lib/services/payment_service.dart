import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String baseUrl = 'http://localhost:3000';

  // Create Stripe customer
  Future<Map<String, dynamic>> createCustomer(
    String email,
    String? name,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/customers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'name': name}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create customer');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent(
    double amount,
    String? customerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/create-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'customerId': customerId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Attach payment method
  Future<Map<String, dynamic>> attachPaymentMethod(
    String paymentMethodId,
    String customerId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments/payment-methods/attach'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentMethodId': paymentMethodId,
          'customerId': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to attach payment method');
      }
    } catch (e) {
      throw Exception('Error attaching payment method: $e');
    }
  }

  // List payment methods
  Future<List<dynamic>> listPaymentMethods(String customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/payment-methods/$customerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to list payment methods');
      }
    } catch (e) {
      throw Exception('Error listing payment methods: $e');
    }
  }
}
