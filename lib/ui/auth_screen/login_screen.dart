import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:driver/controller/auth_controller.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/ui/auth_screen/register_screen.dart';
import 'package:driver/ui/terms_and_condition/terms_and_condition_screen.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    
    return GetX<AuthController>(
      init: AuthController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: controller.loginFormKey.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo and header
                    Center(
                      child: Image.asset(
                        "assets/app_logo.png",
                        width: Responsive.width(40, context),
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    Text(
                      "Welcome Back!".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue driving".tr,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login type selector
                    Container(
                      decoration: BoxDecoration(
                        color: themeChange.getThem() ? AppColors.darkGray : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.loginType.value = "email",
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.loginType.value == "email"
                                      ? (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Email".tr,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: controller.loginType.value == "email"
                                        ? (themeChange.getThem() ? Colors.black : Colors.white)
                                        : (themeChange.getThem() ? Colors.white : Colors.black),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => controller.loginType.value = "phone",
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: controller.loginType.value == "phone"
                                      ? (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Phone".tr,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: controller.loginType.value == "phone"
                                        ? (themeChange.getThem() ? Colors.black : Colors.white)
                                        : (themeChange.getThem() ? Colors.white : Colors.black),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email login form
                    if (controller.loginType.value == "email") ...[
                      TextFormField(
                        controller: controller.loginEmailController.value,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                          color: themeChange.getThem() ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Email Address".tr,
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter email address".tr;
                          }
                          if (!GetUtils.isEmail(value.trim())) {
                            return "Please enter valid email".tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      Obx(() => TextFormField(
                        controller: controller.loginPasswordController.value,
                        obscureText: !controller.isPasswordVisible.value,
                        style: GoogleFonts.poppins(
                          color: themeChange.getThem() ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Password".tr,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isPasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => controller.isPasswordVisible.toggle(),
                          ),
                          filled: true,
                          fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter password".tr;
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters".tr;
                          }
                          return null;
                        },
                      )),
                    ],

                    // Phone login form
                    if (controller.loginType.value == "phone") ...[
                      TextFormField(
                        controller: controller.loginPhoneController.value,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(
                          color: themeChange.getThem() ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: "Phone Number".tr,
                          filled: true,
                          fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                          prefixIcon: CountryCodePicker(
                            onChanged: (value) {
                              controller.countryCode.value = value.dialCode.toString();
                            },
                            initialSelection: controller.countryCode.value,
                            favorite: const ['+1', '+91', '+44'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            dialogBackgroundColor: themeChange.getThem() 
                                ? AppColors.darkBackground 
                                : AppColors.background,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter phone number".tr;
                          }
                          if (value.trim().length < 10) {
                            return "Please enter valid phone number".tr;
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Login button
                    Obx(() => ButtonThem.buildButton(
                      context,
                      title: controller.loginType.value == "phone" 
                          ? "Send OTP".tr 
                          : "Sign In".tr,
                      onPress: controller.isLoading.value ? null : () {
                        if (controller.loginType.value == "email") {
                          controller.loginWithEmail();
                        } else {
                          controller.sendPhoneOTP();
                        }
                      },
                    )),

                    const SizedBox(height: 30),

                    // OR divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "OR".tr,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Social login buttons
                    ButtonThem.buildBorderButton(
                      context,
                      title: "Continue with Google".tr,
                      iconVisibility: true,
                      iconAssetImage: 'assets/icons/ic_google.png',
                      onPress: controller.isLoading.value ? null : controller.signInWithGoogle,
                    ),
                    
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 16),
                      ButtonThem.buildBorderButton(
                        context,
                        title: "Continue with Apple".tr,
                        iconVisibility: true,
                        iconAssetImage: 'assets/icons/ic_apple_gray.png',
                        onPress: controller.isLoading.value ? null : controller.signInWithApple,
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Sign up link
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ".tr,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: "Sign Up".tr,
                              style: GoogleFonts.poppins(
                                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.to(() => const RegisterScreen()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Terms and privacy
                    Center(
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          text: 'By continuing, you agree to our '.tr,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          children: [
                            TextSpan(
                              text: 'Terms of Service'.tr,
                              style: GoogleFonts.poppins(
                                decoration: TextDecoration.underline,
                                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.to(() => const TermsAndConditionScreen(type: "terms")),
                            ),
                            TextSpan(text: ' and '.tr, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            TextSpan(
                              text: 'Privacy Policy'.tr,
                              style: GoogleFonts.poppins(
                                decoration: TextDecoration.underline,
                                color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => Get.to(() => const TermsAndConditionScreen(type: "privacy")),
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
      },
    );
  }
}