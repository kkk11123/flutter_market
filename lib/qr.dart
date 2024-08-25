import 'dart:convert'; // 추가: JSON 인코딩/디코딩

import 'package:cloud_firestore/cloud_firestore.dart'; // 추가: Firestore 임포트
import 'package:flutter/material.dart';
import 'package:flutter_market/item_order_result_page.dart'; // 추가: 결과 페이지 임포트
import 'package:qr_flutter/qr_flutter.dart';

class QRPage extends StatefulWidget {
  final String buyerEmail;
  final double totalPrice;

  const QRPage({Key? key, required this.buyerEmail, required this.totalPrice}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  List<Map<String, dynamic>> orders = [];
  String qrData = "";

  @override
  void initState() {
    super.initState();
    getOrderDataWithDelay();
  }

  void getOrderDataWithDelay() async {
    // 1초 딜레이
    await Future.delayed(Duration(seconds: 1));
    await getOrderData();
  }

  Future<void> getOrderData() async {
    try {
      QuerySnapshot qs = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerEmail', isEqualTo: widget.buyerEmail)
          .get();

      if (qs.docs.isNotEmpty) {
        List<Map<String, dynamic>> ordersData = qs.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            'productName': data['productName'],
            'unitPrice': data['unitPrice'],
            'quantity': data['quantity'],
            'totalPrice': data['totalPrice'],
          };
        }).toList();

        setState(() {
          orders = ordersData;
          qrData = jsonEncode(orders);
        });

        print("QR Data: $qrData");  // QR 코드 데이터 확인을 위한 출력
      } else {
        // 문서가 존재하지 않는 경우 처리
        print("Documents do not exist");
        setState(() {
          qrData = "Documents do not exist";
        });
      }
    } catch (e) {
      print("Error fetching documents: $e");
      setState(() {
        qrData = "Error fetching documents: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("결제 QR"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (qrData.isNotEmpty)
              QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ItemOrderResultPage(
                      paymentAmount: widget.totalPrice,
                      zip: "", // 필요한 데이터로 채우기
                      address1: "",
                      address2: "",
                      orderList: orders, // 주문 데이터 전달
                      quantityList: orders.map((order) => order['quantity'] as int).toList(), // 수량 리스트 전달
                    ),
                  ),
                );
              },
              child: Text("확인"),
            ),
          ],
        ),
      ),
    );
  }
}
