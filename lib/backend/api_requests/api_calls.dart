import '/utils/app_logger.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/environment_values.dart';
import 'api_manager.dart';
import 'interceptors.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// Start OpenAI ChatGPT Orignal Group Code

class OpenAIChatGPTOrignalGroup {
  static String getBaseUrl() => 'https://api.openai.com/v1';
  static Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
  static SendFullPromptCall sendFullPromptCall = SendFullPromptCall();
  static SendFullPromptCopyCall sendFullPromptCopyCall =
      SendFullPromptCopyCall();
  static TitleGeneratorCall titleGeneratorCall = TitleGeneratorCall();
}

class SendFullPromptCall {
  Future<ApiCallResponse> call({
    String? apiKey = '',
    String? prompt = '',
    String? query = '',
    String? language = 'fr',
  }) async {
    final baseUrl = OpenAIChatGPTOrignalGroup.getBaseUrl();

    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are an AI assistant that asks dynamic and personalized questions to understand user preferences better. The user provides a 'language' variable ('en' for English, 'fr' for French). You must generate responses strictly in the specified language. You will receive the full chat history as JSON and must use this context to ask relevant follow-up questions. The first follow-up must always identify who the gift is for (e.g., 'Who is this gift for?' or 'Are you shopping for a friend, family member, or someone else?'). If applicable, ask about the budget.I want you to answer every time with no accent, write the sentences without any accent or special characters like € for example. After these, generate a personalized follow-up question based on the user's answers. \\n\\nFinally, create a 'final_product_query' optimized for e-commerce platforms (Amazon, eBay, Walmart, etc.) when enough details are collected, even if the budget is missing. Additionally, determine whether the product query falls under the category of cosmetics or furniture. If the product is related to cosmetics (e.g., makeup, skincare, perfumes), set 'is_cosmetics' to true. If the product is related to furniture (e.g., chairs, tables, sofas), set 'is_furniture' to true. Otherwise, both should be false.\\n\\nSTRICTLY return a valid JSON object with the following structure: \\n{\\n  \\"follow_up_question\\": \\"Your generated follow-up question here (language should match user input)\\",\\n  \\"final_product_query\\": \\"The optimized product search query\\",\\n  \\"is_cosmetics\\": true/false,\\n  \\"is_furniture\\": true/false\\n}"
    },
    {
      "role": "user",
      "content": "Here is the chat history:${prompt}. The user is looking for a product. Generate a follow-up question based on this input: ${query}. Language preference: ${language}"
    }
  ],
  "temperature": 0.8
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Send Full Prompt ',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? createdTimestamp(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.created''',
      ));
  String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.role''',
      ));
  String? content(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

class SendFullPromptCopyCall {
  Future<ApiCallResponse> call({
    String? apiKey = '',
    String? prompt = '',
    String? query = '',
    String? language = 'fr',
  }) async {
    final baseUrl = OpenAIChatGPTOrignalGroup.getBaseUrl();

    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are an AI assistant that asks dynamic and personalized questions to understand user preferences better. The user provides a 'language' variable ('en' for English, 'fr' for French). You must generate responses strictly in the specified language. You will receive the full chat history as JSON and must use this context to ask relevant follow-up questions. The first follow-up must always identify who the gift is for (e.g., 'Who is this gift for?' or 'Are you shopping for a friend, family member, or someone else?'). If applicable, ask about the budget, but it is optional. After these, generate a personalized follow-up question based on the user's answers. Finally, create a 'final_product_query' optimized for e-commerce platforms (Amazon, eBay, Walmart, etc.) when enough details are collected, even if the budget is missing. STRICTLY return a valid JSON object with the following structure: { \\"follow_up_question\\": \\"Your generated follow-up question here (language should match user input)\\", \\"final_product_query\\": \\"The optimized product search query \\" }"
    },
    {
      "role": "user",
      "content": "Here is the chat history:${prompt}. The user is looking for a product. Generate a follow-up question based on this input: ${query}. Language preference: ${language}"
    }
  ],
  "temperature": 0.8
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Send Full Prompt  Copy',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? createdTimestamp(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.created''',
      ));
  String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.role''',
      ));
  String? content(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

class TitleGeneratorCall {
  Future<ApiCallResponse> call({
    String? apiKey = '',
    String? prompt = '',
  }) async {
    final baseUrl = OpenAIChatGPTOrignalGroup.getBaseUrl();

    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "Given the following chat history in JSON format and I want you to answer every time with no accent, write the sentences without any accent or special characters like € for example, generate a short and relevant title that summarizes the conversation. Only return a JSON object with a single key 'title'. No explanations or extra text.I want you to answer every time with no accent, write the sentences without any accent or special characters like € for example"
    },
    {
      "role": "user",
      "content": "{ \\"chat_history\\":${prompt}}"
    }
  ],
  "temperature": 0.8
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Title Generator',
      apiUrl: '${baseUrl}/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${apiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  int? createdTimestamp(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.created''',
      ));
  String? role(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.role''',
      ));
  String? title(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

/// End OpenAI ChatGPT Orignal Group Code

class OpenAIChatGPTCall {
  static Future<ApiCallResponse> call({
    String? apikey,
    String? question = '',
    String? reponse = '',
    String? query = '',
  }) async {
    apikey ??= FFDevEnvironmentValues().openAiApiKey;
    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "Tu es un assistant qui génère des questions pour aider à trouver un cadeau idéal. RÉPONDS TOUJOURS EN JSON PUR, SANS TEXTE ENCODÉ CAR FLUTTERFLOW NE LE COMPREND PAS, NI FORMATAGE INUTILE. Voici le format strict que tu dois suivre : { \\"question\\": \\"Texte de la question\\", \\"choices\\": [\\"Option 1\\", \\"Option 2\\", \\"Option 3\\"] }. Ne rajoute aucun autre texte, explication ou mise en forme en dehors de ce JSON. Je veux que tu ecrives chaque reponse et chaque titre sans utiliser la moindre majuscule ou caractères specials"
    },
    {
      "role": "user",
      "content": "${escapeStringForJson(query)}"
    }
  ],
  "temperature": 0.7
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'OpenAI ChatGPT',
      apiUrl: 'https://api.openai.com/v1/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer ${FFDevEnvironmentValues().openAiApiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? question(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[0].message.content''',
      ));
  static List? okkk(dynamic response) => getJsonField(
        response,
        r'''$.choices''',
        true,
      ) as List?;
  static dynamic? ok(dynamic response) => getJsonField(
        response,
        r'''$.choices[:].message''',
      );
  static List<String>? okkkk(dynamic response) => (getJsonField(
        response,
        r'''$.choices[:].message.content''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class OpenAiChatGPTAlgoaceCall {
  static Future<ApiCallResponse> call({
    String? query = '',
    String? apikey,
  }) async {
    apikey ??= FFDevEnvironmentValues().openAiApiKey;
    final ffApiRequestBody = '''
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are an assistant that generates precise product search queries optimized for e-commerce platforms like Amazon, eBay, and Walmart. Given user input, return a single search query that can be used directly in e-commerce site search bars. Respond with a single string only, without any explanations or extra text. I want you to answer every time with no accent, write the sentences without any accent or special characters like € for example"
    },
    {
      "role": "user",
      "content": "Generate a product search query based on these details:${escapeStringForJson(query)} "
    }
  ],
  "temperature": 0.7
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'OpenAi ChatGPT  Algoace',
      apiUrl: 'https://api.openai.com/v1/chat/completions',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer ${FFDevEnvironmentValues().openAiApiKey}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? querry(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.choices[:].message.content''',
      ));
}

class AmazonApiSearchAndDiscountsCall {
  static Future<ApiCallResponse> call({
    String? query = ' ',
    String? country = 'us',
    String? keyword = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Amazon Api Search and Discounts',
      apiUrl:
          'https://real-time-amazon-data.p.rapidapi.com/search?page=1&country=US&sort_by=&product_condition=ALL&is_prime=false&deals_and_discounts=ALL_DISCOUNTS',
      callType: ApiCallType.GET,
      headers: {
        'x-rapidapi-host': 'real-time-amazon-data.p.rapidapi.com',
        'x-rapidapi-key': '${FFDevEnvironmentValues().rapidApiKey}',
      },
      params: {
        'query': query,
        'fields':
            "product_num_ratings,product_title,product_price,product_url,product_original_price,product_star_rating,product_photo",
        'country': country,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<ProductsStruct>? productsList(dynamic response) => (getJsonField(
        response,
        r'''$.data.products''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => ProductsStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
}

class AmazonApiForOpenAICall {
  static Future<ApiCallResponse> call({
    String? query = ' ',
    double? minPrice,
    double? maxPrice,
    String? country = 'US',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Amazon Api for OpenAI',
      apiUrl: 'https://real-time-amazon-data.p.rapidapi.com/search',
      callType: ApiCallType.GET,
      headers: {
        'x-rapidapi-host': 'real-time-amazon-data.p.rapidapi.com',
        'x-rapidapi-key': '${FFDevEnvironmentValues().rapidApiKey}',
        'Content-Type': 'application/json',
      },
      params: {
        'query': query,
        'fields':
            "product_num_ratings,product_title,product_price,product_url,product_original_price,product_star_rating,product_photo",
        'country': country,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<ProductsStruct>? productsList(dynamic response) => (getJsonField(
        response,
        r'''$.data.products''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => ProductsStruct.maybeFromMap(x))
          .withoutNulls
          .toList();
}

class SephoraCall {
  static Future<ApiCallResponse> call({
    String? search = '',
    String? query = 'gift',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Sephora',
      apiUrl: 'https://sephora14.p.rapidapi.com/searchByKeyword',
      callType: ApiCallType.GET,
      headers: {
        'x-rapidapi-host': 'sephora14.p.rapidapi.com',
        'x-rapidapi-key': '${FFDevEnvironmentValues().rapidApiSephoraKey}',
      },
      params: {
        'search': search,
        'sortBy': "new",
        'query': query,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? productLink(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].targetUrl''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? totalReviews(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].reviews''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? rating(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].rating''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? imgLink(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].heroImage''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? description(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].displayName''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List? completeProduct(dynamic response) => getJsonField(
        response,
        r'''$.products''',
        true,
      ) as List?;
  static List<String>? price(dynamic response) => (getJsonField(
        response,
        r'''$.products[:].currentSku.listPrice''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class IkeaCall {
  static Future<ApiCallResponse> call({
    String? keyword = '',
    String? countryCode = '',
    String? languageCode = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'Ikea',
      apiUrl:
          'https://ikea-api.p.rapidapi.com/keywordSearch?keyword=decoration&countryCode=us&languageCode=en',
      callType: ApiCallType.GET,
      headers: {
        'x-rapidapi-host': 'ikea-api.p.rapidapi.com',
        'x-rapidapi-key': '${FFDevEnvironmentValues().rapidApiKey}',
      },
      params: {
        'keyword': "accessoires",
        'countryCode': countryCode,
        'languageCode': languageCode,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? producttitle(dynamic response) => (getJsonField(
        response,
        r'''$[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? currency(dynamic response) => (getJsonField(
        response,
        r'''$[:].price.currency''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<String>? productphoto(dynamic response) => (getJsonField(
        response,
        r'''$[:].image''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
  static List<double>? productprice(dynamic response) => (getJsonField(
        response,
        r'''$[:].variants[:].price.currentPrice''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<double>(x))
          .withoutNulls
          .toList();
  static List<String>? producturl(dynamic response) => (getJsonField(
        response,
        r'''$[:].url''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class ZaraCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'Zara',
      apiUrl: 'https://zara-data-api.p.rapidapi.com/categories?language=en_US',
      callType: ApiCallType.GET,
      headers: {
        'x-rapidapi-host': 'zara-data-api.p.rapidapi.com',
        'x-rapidapi-key': '${FFDevEnvironmentValues().rapidApiKey}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      AppLogger.debug("List serialization failed. Returning empty list.", 'Debug');
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      AppLogger.debug("Json serialization failed. Returning empty json.", 'Debug');
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
