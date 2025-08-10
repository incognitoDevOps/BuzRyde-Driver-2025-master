import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/ui/auth_screen/driver_info_screen.dart';
import 'package:driver/ui/auth_screen/login_screen.dart';
import 'package:driver/ui/auth_screen/otp_screen.dart';
import 'package:driver/ui/auth_screen/pending_approval_screen.dart';
import 'package:driver/ui/dashboard_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController extends GetxController {
  // Login form controllers
  Rx<TextEditingController> loginEmailController = TextEditingController().obs;
  Rx<TextEditingController> loginPhoneController = TextEditingController().obs;
  Rx<TextEditingController> loginPasswordController = TextEditingController().obs;
  
  // Registration form controllers
  Rx<TextEditingController> registerFullNameController = TextEditingController().obs;
  Rx<TextEditingController> registerEmailController = TextEditingController().obs;
  Rx<TextEditingController> registerPhoneController = TextEditingController().obs;
  Rx<TextEditingController> registerPasswordController = TextEditingController().obs;
  Rx<TextEditingController> registerConfirmPasswordController = TextEditingController().obs;
  
  // OTP controllers
  Rx<TextEditingController> otpController = TextEditingController().obs;
  
  // Form keys
  Rx<GlobalKey<FormState>> loginFormKey = GlobalKey<FormState>().obs;
  Rx<GlobalKey<FormState>> registerFormKey = GlobalKey<FormState>().obs;
  
  // State variables
  RxString countryCode = "+1".obs;
  RxString verificationId = "".obs;
  RxString loginType = "email".obs; // email, phone, google
  RxBool isPasswordVisible = false.obs;
  RxBool isConfirmPasswordVisible = false.obs;
  RxBool isLoading = false.obs;

  // Email/Password Registration
  Future<void> registerWithEmail() async {
    if (!registerFormKey.value.currentState!.validate()) return;
    
    if (registerPasswordController.value.text != registerConfirmPasswordController.value.text) {
      ShowToastDialog.showToast("Passwords do not match");
      return;
    }

    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Creating account...");

      // Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: registerEmailController.value.text.trim(),
        password: registerPasswordController.value.text,
      );

      // Create driver user model
      DriverUserModel driverUser = DriverUserModel(
        id: userCredential.user!.uid,
        fullName: registerFullNameController.value.text.trim(),
        email: registerEmailController.value.text.trim(),
        phoneNumber: registerPhoneController.value.text.trim(),
        countryCode: countryCode.value,
        password: _hashPassword(registerPasswordController.value.text),
        loginType: Constant.googleLoginType, // Using email login
        profilePic: '',
        documentVerification: false,
        isOnline: false,
        approvalStatus: 'pending',
        profileCompleted: false,
        documentsSubmitted: false,
        reviewsCount: '0.0',
        reviewsSum: '0.0',
        walletAmount: '0.0',
        createdAt: Timestamp.now(),
      );

      // Save to Firestore
      await FireStoreUtils.updateDriverUser(driverUser);
      
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Account created successfully!");
      
      // Navigate to driver info screen
      Get.offAll(() => const DriverInfoScreen());
      
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      String message = "Registration failed";
      
      switch (e.code) {
        case 'weak-password':
          message = "Password is too weak";
          break;
        case 'email-already-in-use':
          message = "Email is already registered";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        default:
          message = e.message ?? "Registration failed";
      }
      
      ShowToastDialog.showToast(message);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Registration failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Email/Password Login
  Future<void> loginWithEmail() async {
    if (!loginFormKey.value.currentState!.validate()) return;

    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Signing in...");

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmailController.value.text.trim(),
        password: loginPasswordController.value.text,
      );

      await _handleSuccessfulLogin(userCredential.user!.uid);
      
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      String message = "Login failed";
      
      switch (e.code) {
        case 'user-not-found':
          message = "No account found with this email";
          break;
        case 'wrong-password':
          message = "Incorrect password";
          break;
        case 'invalid-email':
          message = "Invalid email address";
          break;
        case 'user-disabled':
          message = "Account has been disabled";
          break;
        default:
          message = e.message ?? "Login failed";
      }
      
      ShowToastDialog.showToast(message);
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Login failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Phone number login (send OTP)
  Future<void> sendPhoneOTP() async {
    if (loginPhoneController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter phone number");
      return;
    }

    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Sending OTP...");
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: countryCode.value + loginPhoneController.value.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await FirebaseAuth.instance.signInWithCredential(credential);
          await _handleSuccessfulLogin(FirebaseAuth.instance.currentUser!.uid);
        },
        verificationFailed: (FirebaseAuthException e) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          
          String message = "Verification failed";
          if (e.code == 'invalid-phone-number') {
            message = "Invalid phone number";
          } else {
            message = e.message ?? "Verification failed";
          }
          ShowToastDialog.showToast(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          ShowToastDialog.closeLoader();
          isLoading.value = false;
          this.verificationId.value = verificationId;
          
          Get.to(() => const OtpScreen(), arguments: {
            "countryCode": countryCode.value,
            "phoneNumber": loginPhoneController.value.text.trim(),
            "verificationId": verificationId,
            "isLogin": true,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId.value = verificationId;
        },
      );
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      ShowToastDialog.showToast("Failed to send OTP: ${e.toString()}");
    }
  }

  // Verify OTP for phone login
  Future<void> verifyPhoneOTP(String otp, String verificationId) async {
    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Verifying OTP...");

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo!.isNewUser) {
        // New user - create account and go to driver info
        DriverUserModel driverUser = DriverUserModel(
          id: userCredential.user!.uid,
          phoneNumber: loginPhoneController.value.text.trim(),
          countryCode: countryCode.value,
          loginType: Constant.phoneLoginType,
          profilePic: '',
          documentVerification: false,
          isOnline: false,
          approvalStatus: 'pending',
          profileCompleted: false,
          documentsSubmitted: false,
          reviewsCount: '0.0',
          reviewsSum: '0.0',
          walletAmount: '0.0',
          createdAt: Timestamp.now(),
        );

        await FireStoreUtils.updateDriverUser(driverUser);
        ShowToastDialog.closeLoader();
        Get.offAll(() => const DriverInfoScreen());
      } else {
        // Existing user
        await _handleSuccessfulLogin(userCredential.user!.uid);
      }
      
    } on FirebaseAuthException catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      
      if (e.code == 'invalid-verification-code') {
        ShowToastDialog.showToast("Invalid OTP code");
      } else {
        ShowToastDialog.showToast(e.message ?? "OTP verification failed");
      }
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      ShowToastDialog.showToast("OTP verification failed: ${e.toString()}");
    }
  }

  // Google Sign In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Signing in with Google...");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        ShowToastDialog.closeLoader();
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.additionalUserInfo!.isNewUser) {
        // New user - create account and go to driver info
        DriverUserModel driverUser = DriverUserModel(
          id: userCredential.user!.uid,
          fullName: userCredential.user!.displayName ?? '',
          email: userCredential.user!.email ?? '',
          profilePic: userCredential.user!.photoURL ?? '',
          loginType: Constant.googleLoginType,
          documentVerification: false,
          isOnline: false,
          approvalStatus: 'pending',
          profileCompleted: false,
          documentsSubmitted: false,
          reviewsCount: '0.0',
          reviewsSum: '0.0',
          walletAmount: '0.0',
          createdAt: Timestamp.now(),
        );

        await FireStoreUtils.updateDriverUser(driverUser);
        ShowToastDialog.closeLoader();
        Get.offAll(() => const DriverInfoScreen());
      } else {
        // Existing user
        await _handleSuccessfulLogin(userCredential.user!.uid);
      }
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      ShowToastDialog.showToast("Google sign in failed: ${e.toString()}");
    }
  }

  // Apple Sign In
  Future<void> signInWithApple() async {
    try {
      isLoading.value = true;
      ShowToastDialog.showLoader("Signing in with Apple...");

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      
      if (userCredential.additionalUserInfo!.isNewUser) {
        // New user - create account and go to driver info
        String fullName = '';
        if (appleCredential.givenName != null && appleCredential.familyName != null) {
          fullName = '${appleCredential.givenName} ${appleCredential.familyName}';
        }
        
        DriverUserModel driverUser = DriverUserModel(
          id: userCredential.user!.uid,
          fullName: fullName,
          email: appleCredential.email ?? userCredential.user!.email ?? '',
          profilePic: '',
          loginType: Constant.appleLoginType,
          documentVerification: false,
          isOnline: false,
          approvalStatus: 'pending',
          profileCompleted: false,
          documentsSubmitted: false,
          reviewsCount: '0.0',
          reviewsSum: '0.0',
          walletAmount: '0.0',
          createdAt: Timestamp.now(),
        );

        await FireStoreUtils.updateDriverUser(driverUser);
        ShowToastDialog.closeLoader();
        Get.offAll(() => const DriverInfoScreen());
      } else {
        // Existing user
        await _handleSuccessfulLogin(userCredential.user!.uid);
      }
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      isLoading.value = false;
      ShowToastDialog.showToast("Apple sign in failed: ${e.toString()}");
    }
  }

  // Handle successful login - check user status and navigate accordingly
  Future<void> _handleSuccessfulLogin(String uid) async {
    try {
      DriverUserModel? driverUser = await FireStoreUtils.getDriverProfile(uid);
      
      if (driverUser == null) {
        ShowToastDialog.closeLoader();
        ShowToastDialog.showToast("User profile not found");
        return;
      }

      ShowToastDialog.closeLoader();
      
      // Check user status and navigate accordingly
      if (!driverUser.profileCompleted!) {
        Get.offAll(() => const DriverInfoScreen());
      } else if (driverUser.approvalStatus == 'pending') {
        Get.offAll(() => const PendingApprovalScreen());
      } else if (driverUser.approvalStatus == 'approved') {
        Get.offAll(() => const DashBoardScreen());
      } else {
        ShowToastDialog.showToast("Your account has been rejected. Please contact support.");
      }
      
    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Login failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Utility functions
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Navigation helpers
  void goToLogin() {
    Get.to(() => const LoginScreen());
  }

  void goToRegister() {
    Get.to(() => const RegisterScreen());
  }

  // Clear form data
  void clearForms() {
    loginEmailController.value.clear();
    loginPhoneController.value.clear();
    loginPasswordController.value.clear();
    registerFullNameController.value.clear();
    registerEmailController.value.clear();
    registerPhoneController.value.clear();
    registerPasswordController.value.clear();
    registerConfirmPasswordController.value.clear();
    otpController.value.clear();
  }

  @override
  void onClose() {
    clearForms();
    super.onClose();
  }
}