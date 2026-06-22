import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/auth/firebase_auth/auth_util.dart';

String strToImg(String? stringPathOfImg) {
  return stringPathOfImg ??
      "https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/doron-on1fip/assets/fblzebifgq2c/IMG_1926-1741775187718.jpeg";
}

double getDiscountAmazon(
  String? newPrice,
  String? orginalPrice,
) {
  if (newPrice == null || orginalPrice == null) return 0.0;

  // $ sign hatana aur double me convert karna
  double newP = double.tryParse(newPrice.replaceAll('\$', '')) ?? 0.0;
  double originalP = double.tryParse(orginalPrice.replaceAll('\$', '')) ?? 0.0;

  if (originalP == 0) return 0.0; // Divide by zero ka issue avoid karne ke liye

  // Discount ka formula: ((original - new) / original) * 100
  return ((originalP - newP) / originalP) * 100;
}

dynamic saveChatHistory(
  dynamic chatHistory,
  dynamic newChat,
) {
  // If chatHistory isn't a list, make it a list and then add newChat
  if (chatHistory is List) {
    chatHistory.add(newChat);
    return chatHistory;
  } else {
    return [newChat];
  }
}

dynamic convertToJSON(String prompt) {
  // take the prompt and return a JSON with form [{"role": "user", "content": prompt}]
  return json.decode('{"role": "user", "content": "$prompt"}');
}

List<ProductsStruct>? productsShuffling(List<ProductsStruct>? products) {
  return (products?..shuffle(math.Random()));
}

String getTitle(String? jsonString) {
  if (jsonString == null) return "Invalid JSON";
  try {
    Map<String, dynamic> data = jsonDecode(jsonString);
    return data["title"] ?? "No title found";
  } catch (e) {
    return "Invalid JSON";
  }
}
