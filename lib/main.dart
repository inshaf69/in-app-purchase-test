import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  InAppPurchaseConnection.enablePendingPurchases();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MarkertScreen(),
    );
  }
}

final String testID = 'gem_test';

class MarkertScreen extends StatefulWidget {
  @override
  _MarkertScreenState createState() => _MarkertScreenState();
}

class _MarkertScreenState extends State<MarkertScreen> {
  InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;

  bool _available = true;
  List<ProductDetails> _products = [];

  List<ProductDetails> _purchases = [];

  StreamSubscription _subscription;

  int _credits = 0;

  @override
  void initState() {
    _intialize();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _intialize() async {
    _available = await _iap.isAvailable();
    print(_available);
    if (_available) {
      await _getProducts();
      await _getPastPurchase();
      _verifyPurchase();
      _subscription = _iap.purchaseUpdatedStream.listen((data) => setState(() {
            print('New Purchase');
            _purchases = data.cast<ProductDetails>();
            _verifyPurchase();
          }));
    }
  }

  Future<void> _getProducts() async {
    Set<String> ids = Set.from(['gem_tests']);
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);
    print(response.productDetails);
    if (response.notFoundIDs.isNotEmpty) {
      // Handle the error.
      print('no found');
    }
    setState(() {
      _products = response.productDetails;
    });
  }

  Future<void> _getPastPurchase() async {
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();
    for (PurchaseDetails purchase in response.pastPurchases) {
      if (Platform.isIOS) {
        _iap.completePurchase(purchase);
      }
    }
    setState(() {
      _purchases = response.pastPurchases.cast<ProductDetails>();
    });
  }

  dynamic _hasPurcased(String productID) {
    return _purchases.firstWhere((purchase) => true, orElse: () => null);
  }

  void _buyProducts(ProductDetails prod) async {
    final PurchaseParam purchaseParm = PurchaseParam(productDetails: prod);
    // _iap.buyNonConsumable(purchaseParam: purchaseParm);
    _iap.buyConsumable(purchaseParam: purchaseParm, autoConsume: false);
  }

  void _verifyPurchase() async {
    PurchaseDetails purchase = _hasPurcased(testID);
    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      _credits = 10;
    }
  }

  void _spendCredits(PurchaseDetails purchase) async {
    setState(() {
      _credits--;
    });
    if (_credits == 0) {}
    var res = await _iap.consumePurchase(purchase);
    await _getPastPurchase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text(_available ? 'open for bussiness' : 'not avilable'),
      ),
      body: SingleChildScrollView(
              child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var prod in _products)
                if (_hasPurcased(prod.id) != null) ...[
                  Text(
                    '$_credits',
                    style: TextStyle(fontSize: 60),
                  ),
                  FlatButton(
                    onPressed: () => _spendCredits(_hasPurcased(prod.id)),
                    child: Text('Consume'),
                  ),
                ] else ...[
                  Text(
                    prod.title,
                    style: Theme.of(context).textTheme.headline1,
                  ),
                  Text(prod.description),
                  Text(
                    prod.price,
                  ),
                  FlatButton(
                    onPressed: () => _buyProducts(prod),
                    child: Text('Buy It'),
                    color: Colors.green,
                  )
                ]
            ],
          ),
        ),
      ),
    );
  }
}

// class Test extends StatefulWidget {
//   @override
//   _TestState createState() => _TestState();
// }

// class _TestState extends State<Test> {
//   @override
//   void initState() {
//     _isAvailable();
//     super.initState();
//   }

//   void _isAvailable() async {
//     final bool available = await InAppPurchaseConnection.instance.isAvailable();
//     if (!available) {
//       // The store cannot be reached or accessed. Update the UI accordingly.
//       print(' not available');
//     }
//     print(available);
//     // Set literals require Dart 2.2. Alternatively, use `Set<String> _kIds = <String>['product1', 'product2'].toSet()`.
//     const Set<String> _kIds = {'gem_test'};
//     final ProductDetailsResponse response =
//         await InAppPurchaseConnection.instance.queryProductDetails(_kIds);
//     print(response.error);
//     if (response.notFoundIDs.isNotEmpty) {
//       // Handle the error.
//       print('error');
//     }
//     List<ProductDetails> products = response.productDetails;
//     print(products);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: Text('Test'),
//     );
//   }
// }
