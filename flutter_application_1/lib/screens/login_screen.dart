import 'package:flutter/material.dart';

class LoginDialog extends StatefulWidget {
  final Future<bool> Function(String username, String password) onLogin;
  final Future<bool> Function(String username, String email, String password) onRegister;

  const LoginDialog({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  bool _isLoginMode = true;
  String _username = '';
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Затемнённый фон
        Container(
          color: Colors.black.withOpacity(0.7),
          child: GestureDetector(
            onTap: () {
              // Закрываем диалог при нажатии на фон
              Navigator.of(context).pop();
            },
          ),
        ),
        // Центрированный диалог
        Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLoginMode ? 'Вход' : 'Регистрация',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D3A1A)),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (v) => _username = v,
                    decoration: const InputDecoration(
                      labelText: 'Имя пользователя',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!_isLoginMode) ...[
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => _email = v,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (v) => _password = v,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () async {
                        if (_username.isEmpty || _password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Введите имя пользователя и пароль'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        if (!_isLoginMode && _email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Введите email'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        
                        setState(() => _isLoading = true);
                        
                        try {
                          final success = _isLoginMode
                              ? await widget.onLogin(_username, _password)
                              : await widget.onRegister(_username, _email, _password);
                          
                          if (success && mounted) {
                            // Закрываем диалог
                            Navigator.of(context).pop();
                          } else if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isLoginMode ? 'Неверное имя пользователя или пароль' : 'Ошибка регистрации'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ошибка: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(_isLoginMode ? 'Войти' : 'Зарегистрироваться'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _password = ''; // Очищаем пароль при переключении
                      });
                    },
                    child: Text(
                      _isLoginMode ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}