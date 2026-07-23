import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'recipe_parser.dart';

class AiRecipeService {
  static const String _workerUrl =
      'https://my-cookbook-ai.nyykt6y97y.workers.dev';

  static Future<ParsedRecipe> extractRecipeFromImage({
    required Uint8List imageBytes,
    required String mimeType,
  }) {
    return extractRecipeFromImages(
      images: <RecipeImageUpload>[
        RecipeImageUpload(
          imageBytes: imageBytes,
          mimeType: mimeType,
        ),
      ],
    );
  }

  static Future<ParsedRecipe> extractRecipeFromImages({
    required List<RecipeImageUpload> images,
  }) async {
    if (images.isEmpty) {
      throw Exception('Please select at least one recipe image.');
    }

    for (final RecipeImageUpload image in images) {
      if (image.imageBytes.isEmpty) {
        throw Exception('One of the selected images is empty.');
      }
    }

    final List<Map<String, String>> encodedImages =
        images.map((RecipeImageUpload image) {
      return <String, String>{
        'image': base64Encode(image.imageBytes),
        'mimeType': image.mimeType,
      };
    }).toList();

    final Map<String, dynamic> responseData = await _sendRequest(
      <String, dynamic>{
        'images': encodedImages,
      },
    );

    return _parseResponse(responseData);
  }

  static Future<ParsedRecipe> extractRecipeFromText({
    required String text,
    String? sourceUrl,
  }) async {
    final String cleanedText = text.trim();

    if (cleanedText.isEmpty) {
      throw Exception('Please enter some recipe text.');
    }

    final Map<String, dynamic> requestBody = <String, dynamic>{
      'text': cleanedText,
    };

    if (sourceUrl != null && sourceUrl.trim().isNotEmpty) {
      requestBody['sourceUrl'] = sourceUrl.trim();
    }

    final Map<String, dynamic> responseData =
        await _sendRequest(requestBody);

    return _parseResponse(responseData);
  }

  static Future<Map<String, dynamic>> _sendRequest(
    Map<String, dynamic> requestBody,
  ) async {
    Exception? lastException;

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('AI Attempt $attempt of 3');

        final http.Response response = await http
            .post(
              Uri.parse(_workerUrl),
              headers: const <String, String>{
                'Content-Type': 'application/json',
              },
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 90));

        debugPrint('STATUS CODE: ${response.statusCode}');
        debugPrint('RAW AI RESPONSE: ${response.body}');

        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'The recipe service returned an invalid response.',
          );
        }

        final Map<String, dynamic> responseData = decoded;

        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            responseData['success'] == true) {
          return responseData;
        }

        final String message =
            responseData['message']?.toString().trim() ??
                'Recipe service error ${response.statusCode}.';

        throw Exception(message);
      } on Exception catch (error) {
        lastException = error;

        debugPrint('Attempt $attempt failed: $error');

        if (attempt < 3) {
          await Future<void>.delayed(
            const Duration(seconds: 2),
          );
        }
      }
    }

    throw lastException ??
        Exception(
          'Recipe extraction failed.',
        );
  }

  static ParsedRecipe _parseResponse(
    Map<String, dynamic> responseData,
  ) {
    if (responseData['success'] != true) {
      final String message =
          responseData['message']?.toString().trim() ??
              'The recipe could not be extracted.';

      throw Exception(message);
    }

    final dynamic recipeData = responseData['recipe'];

    if (recipeData is! Map<String, dynamic>) {
      throw Exception(
        'The service did not return any recipe details.',
      );
    }

    final ParsedRecipe recipe = ParsedRecipe();

    recipe.name = _stringValue(recipeData['name']);
    recipe.prepTime = _stringValue(recipeData['prepTime']);
    recipe.cookTime = _stringValue(recipeData['cookTime']);
    recipe.servings = _stringValue(recipeData['servings']);

    recipe.ingredients =
        _stringList(recipeData['ingredients']).join('\n');

    recipe.method =
        _stringList(recipeData['method']).join('\n');

    return recipe;
  }

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList();
  }
}

class RecipeImageUpload {
  final Uint8List imageBytes;
  final String mimeType;

  const RecipeImageUpload({
    required this.imageBytes,
    required this.mimeType,
  });
}