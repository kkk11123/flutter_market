class Product {
  int? productNo;
  String? productName;
  String? productImageUrl;
  double? price;
  String? productWhere; // 새 필드 추가

  Product({
    this.productNo,
    this.productName,
    this.productImageUrl,
    this.price,
    this.productWhere, // 생성자에서 새 필드 초기화
  });

  Product.fromJson(Map<String, dynamic> json) {
    productNo = json['productNo'] as int?;
    productName = json['productName'] as String?;
    productImageUrl = json['productImageUrl'] as String?;
    price = (json['price'] as num?)?.toDouble();
    productWhere = json['productWhere'] as String?; // JSON에서 새 필드 초기화
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['productNo'] = productNo;
    data['productName'] = productName;
    data['productImageUrl'] = productImageUrl;
    data['price'] = price;
    data['productWhere'] = productWhere; // JSON으로 새 필드 추가
    return data;
  }
}
