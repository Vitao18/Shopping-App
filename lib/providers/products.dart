import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './product.dart';

class Products with ChangeNotifier {
  static const url =
      'https://fluttershoppingapp-15671.firebaseio.com/products.json';
  List<Product> _items = [];

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return [..._items.where((product) => product.isFavorite).toList()];
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts() {
    return http.get(url).then((response) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final List<Product> loadedProducts = [];
      data.forEach((prodId, prodData) {
        final newProduct = Product(
          id: prodId,
          title: prodData['title'],
          isFavorite: prodData['isFavorite'],
          price: prodData['price'],
          description: prodData['description'],
          imageUrl: prodData['imageUrl'],
        );
        loadedProducts.add(newProduct);
      });
      _items = loadedProducts;
      notifyListeners();
      print(json.decode(response.body));
    });
  }

  Future<void> addProduct(Product product) {
    return http
        .post(
      url,
      body: json.encode(
        {
          'title': product.title,
          'description': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavorite,
        },
      ),
    )
        .then((response) {
      final id = json.decode(response.body)['name'];
      final newProduct = Product(
        title: product.title,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        id: id,
      );
      _items.add(newProduct);
      notifyListeners();
    }).catchError((error) {
      print(error);
      throw error;
    });
  }

  Future<void> updateProduct(String id, Product newProduct) {
    final prodIndex = _items.indexWhere((product) => product.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://fluttershoppingapp-15671.firebaseio.com/products/$id.json';
      return http
          .patch(
        url,
        body: json.encode({
          'title': newProduct.title,
          'description': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'price': newProduct.price,
        }),
      )
          .then(
        (_) {
          _items[prodIndex] = newProduct;
          notifyListeners();
        },
      );
    } else {
      return Future.value('PRODUCT NOT FOUND!');
    }
  }

  void deleteProduct(String id) {
    final url =
        'https://fluttershoppingapp-15671.firebaseio.com/products/$id.json';
    final existingProductIndex =
        _items.indexWhere((product) => product.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    notifyListeners();
    http.delete(url).then((_) {
      existingProduct = null;
    }).catchError(() {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
    });
  }
}
