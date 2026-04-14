class SellerSessionModel {
  final bool isLoggedIn;
  final bool isSeller;
  final bool isActive;
  final String? userId;

  const SellerSessionModel({
    required this.isLoggedIn,
    required this.isSeller,
    required this.isActive,
    required this.userId,
  });

  const SellerSessionModel.loggedOut()
      : isLoggedIn = false,
        isSeller = false,
        isActive = false,
        userId = null;

  const SellerSessionModel.noSellerAccess({
    required this.userId,
  })  : isLoggedIn = true,
        isSeller = false,
        isActive = false;

  const SellerSessionModel.seller({
    required this.userId,
    required this.isActive,
  })  : isLoggedIn = true,
        isSeller = true;
}
