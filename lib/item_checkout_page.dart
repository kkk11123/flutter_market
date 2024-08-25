import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_market/constants.dart';
import 'package:flutter_market/models/order.dart';
import 'package:flutter_market/models/product.dart';
import 'package:flutter_market/qr.dart'; // 추가: QR 페이지 임포트
import 'package:intl/intl.dart';

class ItemCheckoutPage extends StatefulWidget {
  const ItemCheckoutPage({Key? key}) : super(key: key);

  @override
  State<ItemCheckoutPage> createState() => _ItemCheckoutPageState();
}

class _ItemCheckoutPageState extends State<ItemCheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Query<Product>? productListRef;
  double totalPrice = 0;
  Map<String, dynamic> cartMap = {};
  Stream<QuerySnapshot<Product>>? productList;
  List<int> keyList = [];

  @override
  void initState() {
    super.initState();

    //! 저장한 장바구니 리스트 가져오기
    try {
      cartMap = json.decode(sharedPreferences.getString("cartMap") ?? "{}") ?? {};
    } catch (e) {
      debugPrint(e.toString());
      cartMap = {};
    }

    //! 조건문에 넘길 product no 키 값 리스트를 선언 (기존 값이 string이어서 int로 변환)
    cartMap.forEach((key, value) {
      keyList.add(int.parse(key));
    });

    //! 파이어스토어에서 데이터 가져오는 Ref 변수
    if (keyList.isNotEmpty) {
      productListRef = FirebaseFirestore.instance
          .collection("products")
          .withConverter(
              fromFirestore: (snapshot, _) => Product.fromJson(snapshot.data()!),
              toFirestore: (product, _) => product.toJson())
          .where("productNo", whereIn: keyList);
    }

    productList = productListRef?.orderBy("productNo").snapshots();
  }

  Future<void> _saveOrder() async {
    User? user = _auth.currentUser;

    if (user != null) {
      QuerySnapshot userQuery = await _firestore
          .collection('idpw')
          .where('buyerEmail', isEqualTo: user.email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        var userData = userQuery.docs.first.data() as Map<String, dynamic>;

        var productSnapshot = await productListRef?.get();
        if (productSnapshot != null) {
          for (var document in productSnapshot.docs) {
            Product product = document.data();
            // 각 제품에 대해 새로운 order 문서 생성
            String orderNo = _firestore.collection('orders').doc().id;

            ProductOrder productOrder = ProductOrder(
              orderNo: orderNo,
              productNo: product.productNo,
              orderDate: DateFormat("y-M-d h:m:s").format(DateTime.now()),
              buyerName: userData['buyerName'],
              buyerEmail: userData['buyerEmail'],
              buyerPhone: userData['buyerPhone'],
              userPwd: userData['userPwd'],
              quantity: cartMap[product.productNo.toString()] ?? 0,
              unitPrice: product.price ?? 0,
              totalPrice: (cartMap[product.productNo.toString()] ?? 0) * (product.price ?? 0),
            );

            // Firestore에 주문 저장
            Map<String, dynamic> orderData = productOrder.toJson();
            orderData['productName'] = product.productName; // productName 필드 추가

            await _firestore.collection("orders").doc(orderNo).set(orderData);
          }
        }

        // 주문 저장 후 딜레이 추가
        await Future.delayed(Duration(seconds: 1));

        // QR 코드 생성 페이지로 이동
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => QRPage(buyerEmail: user.email!, totalPrice: totalPrice),
        ));
      } else {
        // 사용자 정보가 없는 경우 처리
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: const Text("사용자 정보를 찾을 수 없습니다."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("닫기"),
                ),
              ],
            );
          },
        );
      }
    } else {
      // 사용자가 로그인하지 않은 경우 처리
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text("로그인이 필요합니다."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("닫기"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("결제확인"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (cartMap.isNotEmpty)
              StreamBuilder(
                stream: productList,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView(
                      shrinkWrap: true,
                      children: snapshot.data!.docs.map((document) {
                        if (cartMap[document.data().productNo.toString()] != null) {
                          return checkoutContainer(
                              productNo: document.data().productNo ?? 0,
                              productName: document.data().productName ?? "",
                              productImageUrl: document.data().productImageUrl ?? "",
                              price: document.data().price ?? 0,
                              quantity: cartMap[document.data().productNo.toString()] ?? 0);
                        }
                        return Container();
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text("오류가 발생 했습니다."),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: cartMap.isEmpty
          ? const Center(
              child: Text("결제할 제품이 없습니다."),
            )
          : StreamBuilder(
              stream: productList,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  totalPrice = 0;
                  snapshot.data?.docs.forEach((document) {
                    if (cartMap[document.data().productNo.toString()] != null) {
                      totalPrice += cartMap[document.data().productNo.toString()]! * document.data().price ?? 0;
                    }
                  });
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: FilledButton(
                      onPressed: _saveOrder,
                      child: Text("총 ${numberFormat.format(totalPrice)}원 결제하기"),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text("오류가 발생 했습니다."),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget checkoutContainer({
    required int productNo,
    required String productName,
    required String productImageUrl,
    required double price,
    required int quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 130,
            fit: BoxFit.cover,
            imageUrl: productImageUrl,
            placeholder: (context, url) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            },
            errorWidget: (context, url, error) {
              return const Center(
                child: Text("오류 발생"),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  productName,
                  textScaleFactor: 1.2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("${numberFormat.format(price)}원"),
                Text("$quantity개"),
                Text("합계 : ${numberFormat.format(quantity * price)}원"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
