class CheckoutValidator {
  static String? validate({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneRaw,
  }) {
    final phone = phoneRaw.replaceAll(' ', '');

    if (firstName.isEmpty) return "First name is required.";
    if (lastName.isEmpty) return "Last name is required.";
    if (email.isEmpty) return "Email address is required.";
    if (phone.isEmpty) return "Mobile number is required.";

    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(firstName)) return "First name can only contain letters.";
    if (!nameRegex.hasMatch(lastName)) return "Last name can only contain letters.";

    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(email)) return "Please enter a valid email address.";

    final nzPhoneRegex = RegExp(r"^[2]\d{7,9}$");
    if (!nzPhoneRegex.hasMatch(phone)) return "Please enter a valid NZ mobile number.";

    return null; 
  }
}