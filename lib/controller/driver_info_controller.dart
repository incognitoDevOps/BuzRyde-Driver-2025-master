import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/constant/show_toast_dialog.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/driver_document_model.dart';
import 'package:driver/model/driver_user_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/ui/auth_screen/pending_approval_screen.dart';
import 'package:driver/utils/fire_store_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DriverInfoController extends GetxController {
  // Personal Information
  Rx<TextEditingController> fullNameController = TextEditingController().obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> phoneController = TextEditingController().obs;
  RxString countryCode = "+1".obs;
  RxString profileImagePath = "".obs;

  // Vehicle Information
  Rx<TextEditingController> vehicleNumberController = TextEditingController().obs;
  Rx<TextEditingController> registrationDateController = TextEditingController().obs;
  Rx<TextEditingController> seatsController = TextEditingController().obs;
  Rx<DateTime?> selectedRegistrationDate = DateTime.now().obs;
  
  // Dropdowns
  Rx<ServiceModel> selectedService = ServiceModel().obs;
  Rx<VehicleTypeModel> selectedVehicleType = VehicleTypeModel().obs;
  RxString selectedVehicleColor = "".obs;
  RxList<String> selectedZoneIds = <String>[].obs;
  RxString selectedZoneNames = "".obs;

  // Document Upload
  RxMap<String, String> documentImages = <String, String>{}.obs; // documentId -> imagePath
  RxMap<String, TextEditingController> documentNumberControllers = <String, TextEditingController>{}.obs;
  RxMap<String, DateTime?> documentExpiryDates = <String, DateTime?>{}.obs;

  // Data Lists
  RxList<ServiceModel> serviceList = <ServiceModel>[].obs;
  RxList<VehicleTypeModel> vehicleTypeList = <VehicleTypeModel>[].obs;
  RxList<ZoneModel> zoneList = <ZoneModel>[].obs;
  RxList<DocumentModel> documentList = <DocumentModel>[].obs;
  
  // UI State
  RxInt currentStep = 0.obs;
  RxBool isLoading = true.obs;
  RxBool isSubmitting = false.obs;

  // Constants
  final List<String> vehicleColors = [
    'Red', 'Black', 'White', 'Blue', 'Green', 'Orange', 
    'Silver', 'Gray', 'Yellow', 'Brown', 'Gold', 'Beige', 'Purple'
  ];
  
  final List<String> seatOptions = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15'
  ];

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      
      // Load current user data
      DriverUserModel? currentUser = await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser != null) {
        _populateUserData(currentUser);
      }

      // Load dropdown data
      await Future.wait([
        _loadServices(),
        _loadVehicleTypes(),
        _loadZones(),
        _loadDocuments(),
      ]);

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      ShowToastDialog.showToast("Failed to load data: ${e.toString()}");
    }
  }

  void _populateUserData(DriverUserModel user) {
    fullNameController.value.text = user.fullName ?? '';
    emailController.value.text = user.email ?? '';
    phoneController.value.text = user.phoneNumber ?? '';
    countryCode.value = user.countryCode ?? '+1';
    profileImagePath.value = user.profilePic ?? '';

    if (user.vehicleInformation != null) {
      vehicleNumberController.value.text = user.vehicleInformation!.vehicleNumber ?? '';
      selectedVehicleColor.value = user.vehicleInformation!.vehicleColor ?? '';
      seatsController.value.text = user.vehicleInformation!.seats ?? '2';
      
      if (user.vehicleInformation!.registrationDate != null) {
        selectedRegistrationDate.value = user.vehicleInformation!.registrationDate!.toDate();
        registrationDateController.value.text = DateFormat("dd-MM-yyyy").format(selectedRegistrationDate.value!);
      }
    }

    if (user.zoneIds != null) {
      selectedZoneIds.value = List<String>.from(user.zoneIds!);
    }
  }

  Future<void> _loadServices() async {
    List<ServiceModel> services = await FireStoreUtils.getService();
    serviceList.value = services;
  }

  Future<void> _loadVehicleTypes() async {
    List<VehicleTypeModel>? types = await FireStoreUtils.getVehicleType();
    if (types != null) {
      vehicleTypeList.value = types;
    }
  }

  Future<void> _loadZones() async {
    List<ZoneModel>? zones = await FireStoreUtils.getZone();
    if (zones != null) {
      zoneList.value = zones;
    }
  }

  Future<void> _loadDocuments() async {
    List<DocumentModel> documents = await FireStoreUtils.getDocumentList();
    documentList.value = documents;
    
    // Initialize controllers for each document
    for (DocumentModel doc in documents) {
      documentNumberControllers[doc.id!] = TextEditingController();
    }
  }

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickProfileImage() async {
    try {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        profileImagePath.value = image.path;
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: ${e.message}");
    }
  }

  Future<void> pickDocumentImage(String documentId, {bool isFrontSide = true}) async {
    try {
      XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        String key = isFrontSide ? '${documentId}_front' : '${documentId}_back';
        documentImages[key] = image.path;
      }
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("Failed to pick image: ${e.message}");
    }
  }

  // Zone selection
  void updateSelectedZones() {
    List<String> zoneNames = [];
    for (String zoneId in selectedZoneIds) {
      ZoneModel? zone = zoneList.firstWhereOrNull((z) => z.id == zoneId);
      if (zone != null) {
        zoneNames.add(zone.name!);
      }
    }
    selectedZoneNames.value = zoneNames.join(', ');
  }

  // Step navigation
  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  void goToStep(int step) {
    currentStep.value = step;
  }

  // Validation
  bool validatePersonalInfo() {
    if (fullNameController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your full name");
      return false;
    }
    if (emailController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your email");
      return false;
    }
    if (!Constant.validateEmail(emailController.value.text.trim())!) {
      ShowToastDialog.showToast("Please enter a valid email");
      return false;
    }
    if (phoneController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter your phone number");
      return false;
    }
    return true;
  }

  bool validateVehicleInfo() {
    if (selectedService.value.id == null) {
      ShowToastDialog.showToast("Please select a service type");
      return false;
    }
    if (vehicleNumberController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please enter vehicle number");
      return false;
    }
    if (selectedVehicleType.value.id == null) {
      ShowToastDialog.showToast("Please select vehicle type");
      return false;
    }
    if (selectedVehicleColor.value.isEmpty) {
      ShowToastDialog.showToast("Please select vehicle color");
      return false;
    }
    if (seatsController.value.text.trim().isEmpty) {
      ShowToastDialog.showToast("Please select number of seats");
      return false;
    }
    if (selectedRegistrationDate.value == null) {
      ShowToastDialog.showToast("Please select registration date");
      return false;
    }
    if (selectedZoneIds.isEmpty) {
      ShowToastDialog.showToast("Please select at least one zone");
      return false;
    }
    return true;
  }

  bool validateDocuments() {
    for (DocumentModel doc in documentList) {
      // Check document number
      if (documentNumberControllers[doc.id]?.text.trim().isEmpty ?? true) {
        ShowToastDialog.showToast("Please enter ${doc.title} number");
        return false;
      }
      
      // Check front side image
      if (doc.frontSide == true && !documentImages.containsKey('${doc.id}_front')) {
        ShowToastDialog.showToast("Please upload front side of ${doc.title}");
        return false;
      }
      
      // Check back side image
      if (doc.backSide == true && !documentImages.containsKey('${doc.id}_back')) {
        ShowToastDialog.showToast("Please upload back side of ${doc.title}");
        return false;
      }
      
      // Check expiry date
      if (doc.expireAt == true && documentExpiryDates[doc.id] == null) {
        ShowToastDialog.showToast("Please select expiry date for ${doc.title}");
        return false;
      }
    }
    return true;
  }

  // Submit all information
  Future<void> submitDriverInfo() async {
    if (!validatePersonalInfo() || !validateVehicleInfo() || !validateDocuments()) {
      return;
    }

    try {
      isSubmitting.value = true;
      ShowToastDialog.showLoader("Submitting information...");

      // Upload profile image if selected
      String profileImageUrl = profileImagePath.value;
      if (profileImagePath.value.isNotEmpty && !Constant().hasValidUrl(profileImagePath.value)) {
        profileImageUrl = await Constant.uploadUserImageToFireStorage(
          File(profileImagePath.value),
          "profileImages/${FireStoreUtils.getCurrentUid()}",
          "profile_${DateTime.now().millisecondsSinceEpoch}.jpg"
        );
      }

      // Upload document images
      Map<String, String> uploadedDocumentUrls = {};
      for (String key in documentImages.keys) {
        if (!Constant().hasValidUrl(documentImages[key]!)) {
          String url = await Constant.uploadUserImageToFireStorage(
            File(documentImages[key]!),
            "driverDocuments/${FireStoreUtils.getCurrentUid()}",
            "${key}_${DateTime.now().millisecondsSinceEpoch}.jpg"
          );
          uploadedDocumentUrls[key] = url;
        } else {
          uploadedDocumentUrls[key] = documentImages[key]!;
        }
      }

      // Create vehicle information
      VehicleInformation vehicleInfo = VehicleInformation(
        vehicleNumber: vehicleNumberController.value.text.trim(),
        vehicleType: selectedVehicleType.value.name,
        vehicleTypeId: selectedVehicleType.value.id,
        vehicleColor: selectedVehicleColor.value,
        seats: seatsController.value.text.trim(),
        registrationDate: Timestamp.fromDate(selectedRegistrationDate.value!),
      );

      // Update driver user model
      DriverUserModel? currentUser = await FireStoreUtils.getDriverProfile(FireStoreUtils.getCurrentUid());
      if (currentUser != null) {
        currentUser.fullName = fullNameController.value.text.trim();
        currentUser.email = emailController.value.text.trim();
        currentUser.phoneNumber = phoneController.value.text.trim();
        currentUser.countryCode = countryCode.value;
        currentUser.profilePic = profileImageUrl;
        currentUser.serviceId = selectedService.value.id;
        currentUser.vehicleInformation = vehicleInfo;
        currentUser.zoneIds = selectedZoneIds;
        currentUser.profileCompleted = true;
        currentUser.documentsSubmitted = true;
        currentUser.approvalStatus = 'pending';

        await FireStoreUtils.updateDriverUser(currentUser);
      }

      // Upload documents
      await _uploadDocuments(uploadedDocumentUrls);

      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Information submitted successfully!");
      
      // Navigate to pending approval screen
      Get.offAll(() => const PendingApprovalScreen());

    } catch (e) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast("Failed to submit information: ${e.toString()}");
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _uploadDocuments(Map<String, String> uploadedUrls) async {
    List<Documents> documentsList = [];

    for (DocumentModel doc in documentList) {
      Documents document = Documents();
      document.documentId = doc.id;
      document.documentNumber = documentNumberControllers[doc.id]?.text.trim();
      document.verified = false;

      // Set front image
      if (doc.frontSide == true) {
        document.frontImage = uploadedUrls['${doc.id}_front'] ?? '';
      }

      // Set back image
      if (doc.backSide == true) {
        document.backImage = uploadedUrls['${doc.id}_back'] ?? '';
      }

      // Set expiry date
      if (doc.expireAt == true && documentExpiryDates[doc.id] != null) {
        document.expireAt = Timestamp.fromDate(documentExpiryDates[doc.id]!);
      }

      documentsList.add(document);
    }

    // Create driver document model
    DriverDocumentModel driverDocumentModel = DriverDocumentModel(
      id: FireStoreUtils.getCurrentUid(),
      documents: documentsList,
    );

    // Upload to Firestore
    await FirebaseFirestore.instance
        .collection('driver_document')
        .doc(FireStoreUtils.getCurrentUid())
        .set(driverDocumentModel.toJson());
  }

  // Date picker
  Future<void> selectRegistrationDate() async {
    DateTime? picked = await Constant.selectDate(Get.context!);
    if (picked != null) {
      selectedRegistrationDate.value = picked;
      registrationDateController.value.text = DateFormat("dd-MM-yyyy").format(picked);
    }
  }

  Future<void> selectDocumentExpiryDate(String documentId) async {
    DateTime? picked = await Constant.selectFetureDate(Get.context!);
    if (picked != null) {
      documentExpiryDates[documentId] = picked;
    }
  }

  @override
  void onClose() {
    // Clean up controllers
    for (TextEditingController controller in documentNumberControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }
}