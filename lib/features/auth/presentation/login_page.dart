import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../services/api_service.dart';
import '../../parcours/presentation/parcours_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorText;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final ok = await ApiService.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ParcoursListPage(),
          ),
        );
      } else {
        setState(() {
          errorText = "Identifiants invalides";
        });
      }
    } catch (e) {
      setState(() {
        errorText = "Impossible de se connecter au serveur";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Ensemble face à la prolifération du',
                  style: TextStyle(
                    fontFamily: 'Gabarito',
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const Text(
                  'moustique tigre',
                  style: TextStyle(
                    fontFamily: 'Gabarito',
                    fontSize: 25,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentRed,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  style: const TextStyle(
                    fontFamily: 'Gabarito',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                  ),
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    labelStyle: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(
                    fontFamily: 'Gabarito',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: const TextStyle(
                      fontFamily: 'Gabarito',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGrey,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Gabarito',
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontFamily: 'Gabarito',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Image(
                                image:
                                    AssetImage('assets/icons/login-icon.png'),
                                height: 22,
                                width: 22,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
