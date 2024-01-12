
class Categoryy {
  const Categoryy({
    required this.id,
    required this.title,
    required this.color,
  });

  final String id;
  final String title;
  final String color;

  factory Categoryy.fromMap(Map<String, dynamic> data) {
  return Categoryy(id: data['id'], title: data['title'], color: data['color']);
 }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'color': color,
    };
  }

}
