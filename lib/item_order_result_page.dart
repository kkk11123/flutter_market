import 'package:flutter/material.dart';
import 'package:flutter_market/constants.dart';
import 'package:flutter_market/item_list_page.dart'; // Add import for ItemListPage

class ItemOrderResultPage extends StatefulWidget {
  ItemOrderResultPage({
    super.key,
    required this.paymentAmount,
    required this.zip,
    required this.address1,
    required this.address2,
    required this.orderList,
    required this.quantityList,
  });

  double paymentAmount;
  String receiverName = "";
  String receiverPhone = "";
  String zip;
  String address1;
  String address2;
  List<Map<String, dynamic>> orderList; // Define orderList
  List<int> quantityList; // Define quantityList

  @override
  State<ItemOrderResultPage> createState() => _ItemOrderResultPageState();
}

class _ItemOrderResultPageState extends State<ItemOrderResultPage> {
  late List<Map<String, dynamic>> orderList;
  late List<int> quantityList;

  @override
  void initState() {
    super.initState();
    orderList = widget.orderList; // Initialize orderList from widget
    quantityList = widget.quantityList; // Initialize quantityList from widget
  }

  String generateOrderNumber() {
    final dateTime = DateTime.now();
    String orderNo =
        "${dateTime.year}${dateTime.month}${dateTime.day}-${dateTime.hour}${dateTime.minute}${dateTime.millisecond}";
    return orderNo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.9),
      appBar: AppBar(
        title: const Text("결제완료"),
        centerTitle: true,
      ),
      body: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(8),
                child: const Text("결제가 완료되었습니다.", textScaleFactor: 1.2),
              ),
              //! 주문정보관련
              Container(
                margin: const EdgeInsets.all(30),
                padding: const EdgeInsets.only(top: 10),
                color: Colors.white,
                child: Column(
                  children: [
                    orderNumberRow(), // 결제 번호
                    const Divider(), // 구분선
                    paymentInfoRow(), // 구매 정보
                    const Divider(), // 구분선
                    paymentAmountRow(), // 결제 금액
                    const Divider(), // 구분선
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: () {
            // Navigate to ItemListPage
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => ItemListPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: const Text("홈으로"),
        ),
      ),
    );
  }

  Widget paymentInfoRow() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // 변경된 부분
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(
                flex: 4,
                child: Text("결제 정보", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < orderList.length; i++)
                      Text("${orderList[i]['productName']} (${quantityList[i]}개)"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget paymentAmountRow() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            flex: 4,
            child: Text("결제금액"),
          ),
          Expanded(
            flex: 6,
            child: Text("${numberFormat.format(widget.paymentAmount)}원"),
          ),
        ],
      ),
    );
  }

  Widget orderNumberRow() {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Expanded(
            flex: 4,
            child: Text("결제번호"),
          ),
          Expanded(
            flex: 6,
            child: Text(generateOrderNumber()),
          )
        ],
      ),
    );
  }
}
