/// Erro vindo da API. [toString] devolve só a mensagem, para poder ser
/// exibida direto em um SnackBar (o backend já envia textos em português
/// para os casos esperados, como 409 de duplicidade).
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}
