import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/typography.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../router/app_router.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/gradient_mesh_background.dart';
import '../../widgets/common/styled_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // Router redirect handles navigation after auth state changes
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return GradientMeshScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.grid_view_rounded,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: AppTypography.headlineLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 8),
                Text(
                  'Start tracking your goals',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 40),

                // Name field
                StyledTextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  labelText: 'Name',
                  hintText: 'Your name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // Email field
                StyledTextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),

                // Password field
                StyledTextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  labelText: 'Password',
                  hintText: 'Min 6 characters',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  onSubmitted: (_) => _register(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.2, end: 0),

                // Error message
                if (authState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      authState.error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),

                // Register button
                GradientButton(
                  label: 'Create Account',
                  onPressed: authState.isLoading ? null : _register,
                  isLoading: authState.isLoading,
                ).animate(delay: 600.ms).fadeIn(),
                const SizedBox(height: 16),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: Text(
                        'Sign In',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate(delay: 700.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
