class User {
  int id;
  String firstname;
  String lastname;
  String email;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  // empty constructor
  User.empty()
      : id = 0,
        firstname = '',
        lastname = '',
        email = '';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstname: json['firstname'],
      lastname: json['lastname'],
      email: json['email']
    );
  }
}
