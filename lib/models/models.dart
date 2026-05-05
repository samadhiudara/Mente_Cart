// ─── User ────────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String email;
  final String name;

  const UserModel({required this.id, required this.email, required this.name});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
      );
}

// ─── TimeSlot ────────────────────────────────────────────────────────────────

class TimeSlotModel {
  final String id;
  final String date;
  final String time;
  final int capacity;
  final int booked;

  const TimeSlotModel({
    required this.id,
    required this.date,
    required this.time,
    required this.capacity,
    required this.booked,
  });

  int get available => capacity - booked;
  bool get isFull => available <= 0;

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) => TimeSlotModel(
        id: json['_id'] as String? ?? '',
        date: json['date'] as String,
        time: json['time'] as String,
        capacity: json['capacity'] as int,
        booked: json['booked'] as int? ?? 0,
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class ServiceModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final int duration;
  final String category;
  final String image;
  final int capacityPerSlot;
  final List<TimeSlotModel> slots;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.image,
    required this.capacityPerSlot,
    required this.slots,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        price: (json['price'] as num).toDouble(),
        duration: json['duration'] as int,
        category: json['category'] as String,
        image: json['image'] as String? ?? '',
        capacityPerSlot: json['capacityPerSlot'] as int,
        slots: (json['slots'] as List<dynamic>? ?? [])
            .map((s) => TimeSlotModel.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Cart ─────────────────────────────────────────────────────────────────────

class CartItemModel {
  final String id;
  final String serviceId;
  final String? serviceTitle;
  final String? serviceImage;
  final String slotDate;
  final String slotTime;
  final int quantity;
  final double price;
  final DateTime expiresAt;

  const CartItemModel({
    required this.id,
    required this.serviceId,
    this.serviceTitle,
    this.serviceImage,
    required this.slotDate,
    required this.slotTime,
    required this.quantity,
    required this.price,
    required this.expiresAt,
  });

  double get subtotal => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final svc = json['serviceId'];
    String serviceId;
    String? serviceTitle;
    String? serviceImage;

    if (svc is Map<String, dynamic>) {
      serviceId = svc['_id'] as String;
      serviceTitle = svc['title'] as String?;
      serviceImage = svc['image'] as String?;
    } else {
      serviceId = svc as String;
    }

    return CartItemModel(
      id: json['_id'] as String,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      serviceImage: serviceImage,
      slotDate: json['slotDate'] as String,
      slotTime: json['slotTime'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class CartModel {
  final String id;
  final List<CartItemModel> items;
  final int itemCount;
  final double total;

  const CartModel({
    required this.id,
    required this.items,
    required this.itemCount,
    required this.total,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
        id: json['_id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((i) => CartItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        itemCount: json['itemCount'] as int,
        total: (json['total'] as num).toDouble(),
      );
}

// ─── Booking ─────────────────────────────────────────────────────────────────

class BookingItemModel {
  final String serviceId;
  final String serviceTitle;
  final String slotDate;
  final String slotTime;
  final int quantity;
  final double price;

  const BookingItemModel({
    required this.serviceId,
    required this.serviceTitle,
    required this.slotDate,
    required this.slotTime,
    required this.quantity,
    required this.price,
  });

  factory BookingItemModel.fromJson(Map<String, dynamic> json) =>
      BookingItemModel(
        serviceId: json['serviceId'] as String,
        serviceTitle: json['serviceTitle'] as String,
        slotDate: json['slotDate'] as String,
        slotTime: json['slotTime'] as String,
        quantity: json['quantity'] as int,
        price: (json['price'] as num).toDouble(),
      );
}

class BookingModel {
  final String id;
  final List<BookingItemModel> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime cancelCutoff;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.cancelCutoff,
    required this.createdAt,
  });

  bool get canCancel =>
      (status == 'pending' || status == 'confirmed') &&
      DateTime.now().isBefore(cancelCutoff);

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['_id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((i) => BookingItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        status: json['status'] as String,
        paymentMethod: json['paymentMethod'] as String,
        paymentStatus: json['paymentStatus'] as String,
        cancelCutoff: DateTime.parse(json['cancelCutoff'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PaginatedServices {
  final List<ServiceModel> data;
  final int page;
  final int total;
  final bool hasMore;

  const PaginatedServices({
    required this.data,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedServices.fromJson(Map<String, dynamic> json) =>
      PaginatedServices(
        data: (json['data'] as List<dynamic>)
            .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
            .toList(),
        page: json['page'] as int,
        total: json['total'] as int,
        hasMore: json['hasMore'] as bool,
      );
}
