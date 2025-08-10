import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:driver/constant/constant.dart';
import 'package:driver/controller/driver_info_controller.dart';
import 'package:driver/model/document_model.dart';
import 'package:driver/model/service_model.dart';
import 'package:driver/model/vehicle_type_model.dart';
import 'package:driver/model/zone_model.dart';
import 'package:driver/themes/app_colors.dart';
import 'package:driver/themes/button_them.dart';
import 'package:driver/themes/responsive.dart';
import 'package:driver/themes/text_field_them.dart';
import 'package:driver/utils/DarkThemeProvider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DriverInfoScreen extends StatelessWidget {
  const DriverInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    
    return GetX<DriverInfoController>(
      init: DriverInfoController(),
      builder: (controller) {
        if (controller.isLoading.value) {
          return Scaffold(
            body: Center(child: Constant.loader(context)),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            backgroundColor: themeChange.getThem() ? AppColors.darkBackground : AppColors.primary,
            title: Text(
              "Driver Information".tr,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(20),
                color: themeChange.getThem() ? AppColors.darkBackground : AppColors.primary,
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= controller.currentStep.value
                                ? AppColors.darkModePrimary
                                : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < 2) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              
              // Step content
              Expanded(
                child: PageView(
                  controller: PageController(initialPage: controller.currentStep.value),
                  onPageChanged: (index) => controller.currentStep.value = index,
                  children: [
                    _buildPersonalInfoStep(context, controller, themeChange),
                    _buildVehicleInfoStep(context, controller, themeChange),
                    _buildDocumentsStep(context, controller, themeChange),
                  ],
                ),
              ),
              
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (controller.currentStep.value > 0)
                      Expanded(
                        child: ButtonThem.buildBorderButton(
                          context,
                          title: "Previous".tr,
                          onPress: controller.previousStep,
                        ),
                      ),
                    if (controller.currentStep.value > 0) const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => ButtonThem.buildButton(
                        context,
                        title: controller.currentStep.value == 2 
                            ? "Submit for Approval".tr 
                            : "Next".tr,
                        onPress: controller.isSubmitting.value ? null : () {
                          if (controller.currentStep.value == 0) {
                            if (controller.validatePersonalInfo()) {
                              controller.nextStep();
                            }
                          } else if (controller.currentStep.value == 1) {
                            if (controller.validateVehicleInfo()) {
                              controller.nextStep();
                            }
                          } else {
                            controller.submitDriverInfo();
                          }
                        },
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfoStep(BuildContext context, DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Information".tr,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about yourself".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Profile Image
          Center(
            child: GestureDetector(
              onTap: controller.pickProfileImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeChange.getThem() ? AppColors.darkGray : AppColors.lightGray,
                  border: Border.all(
                    color: themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary,
                    width: 3,
                  ),
                ),
                child: Obx(() {
                  if (controller.profileImagePath.value.isNotEmpty) {
                    return ClipOval(
                      child: controller.profileImagePath.value.startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: controller.profileImagePath.value,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            )
                          : Image.file(
                              File(controller.profileImagePath.value),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                    );
                  }
                  return Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: themeChange.getThem() ? Colors.white : Colors.grey[600],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Full Name
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'Full Name'.tr,
            controller: controller.fullNameController.value,
          ),
          const SizedBox(height: 20),

          // Email
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'Email Address'.tr,
            controller: controller.emailController.value,
            keyBoardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),

          // Phone Number
          TextFormField(
            controller: controller.phoneController.value,
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
                dialogBackgroundColor: themeChange.getThem() 
                    ? AppColors.darkBackground 
                    : AppColors.background,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoStep(BuildContext context, DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vehicle Information".tr,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tell us about your vehicle".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Service Type
          Text("Service Type".tr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.serviceList.length,
              itemBuilder: (context, index) {
                ServiceModel service = controller.serviceList[index];
                bool isSelected = controller.selectedService.value.id == service.id;
                
                return GestureDetector(
                  onTap: () => controller.selectedService.value = service,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary)
                          : (themeChange.getThem() ? AppColors.darkGray : AppColors.lightGray),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (themeChange.getThem() ? AppColors.darkModePrimary : AppColors.primary)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: service.image ?? '',
                          width: 40,
                          height: 40,
                          errorWidget: (context, url, error) => const Icon(Icons.directions_car),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.title ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? (themeChange.getThem() ? Colors.black : Colors.white)
                                : (themeChange.getThem() ? Colors.white : Colors.black),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Vehicle Number
          TextFieldThem.buildTextFiled(
            context,
            hintText: 'Vehicle Number'.tr,
            controller: controller.vehicleNumberController.value,
          ),
          const SizedBox(height: 20),

          // Vehicle Type
          DropdownButtonFormField<VehicleTypeModel>(
            decoration: InputDecoration(
              labelText: "Vehicle Type".tr,
              filled: true,
              fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: controller.selectedVehicleType.value.id == null ? null : controller.selectedVehicleType.value,
            items: controller.vehicleTypeList.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name ?? ''),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedVehicleType.value = value;
              }
            },
          ),
          const SizedBox(height: 20),

          // Vehicle Color
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Vehicle Color".tr,
              filled: true,
              fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: controller.selectedVehicleColor.value.isEmpty ? null : controller.selectedVehicleColor.value,
            items: controller.vehicleColors.map((color) {
              return DropdownMenuItem(
                value: color,
                child: Text(color),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.selectedVehicleColor.value = value;
              }
            },
          ),
          const SizedBox(height: 20),

          // Number of Seats
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Number of Seats".tr,
              filled: true,
              fillColor: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            value: controller.seatsController.value.text.isEmpty ? null : controller.seatsController.value.text,
            items: controller.seatOptions.map((seats) {
              return DropdownMenuItem(
                value: seats,
                child: Text(seats),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.seatsController.value.text = value;
              }
            },
          ),
          const SizedBox(height: 20),

          // Registration Date
          GestureDetector(
            onTap: controller.selectRegistrationDate,
            child: TextFieldThem.buildTextFiledWithSuffixIcon(
              context,
              hintText: 'Registration Date'.tr,
              controller: controller.registrationDateController.value,
              enable: false,
              suffixIcon: const Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 20),

          // Zone Selection
          GestureDetector(
            onTap: () => _showZoneSelectionDialog(context, controller),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.selectedZoneNames.value.isEmpty
                          ? "Select Operating Zones".tr
                          : controller.selectedZoneNames.value,
                      style: GoogleFonts.poppins(
                        color: controller.selectedZoneNames.value.isEmpty
                            ? Colors.grey[600]
                            : (themeChange.getThem() ? Colors.white : Colors.black),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep(BuildContext context, DriverInfoController controller, DarkThemeProvider themeChange) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Required Documents".tr,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload your documents for verification".tr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          // Documents list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.documentList.length,
            itemBuilder: (context, index) {
              DocumentModel document = controller.documentList[index];
              return _buildDocumentCard(context, controller, document, themeChange);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DriverInfoController controller, DocumentModel document, DarkThemeProvider themeChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeChange.getThem() ? AppColors.darkContainerBackground : AppColors.containerBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeChange.getThem() ? AppColors.darkContainerBorder : AppColors.containerBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title ?? '',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Document Number
          TextFieldThem.buildTextFiled(
            context,
            hintText: '${document.title} Number'.tr,
            controller: controller.documentNumberControllers[document.id]!,
          ),
          const SizedBox(height: 16),

          // Expiry Date (if required)
          if (document.expireAt == true) ...[
            GestureDetector(
              onTap: () => controller.selectDocumentExpiryDate(document.id!),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeChange.getThem() ? AppColors.darkTextField : AppColors.textField,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        DateTime? date = controller.documentExpiryDates[document.id];
                        return Text(
                          date != null
                              ? DateFormat("dd-MM-yyyy").format(date)
                              : "Select Expiry Date".tr,
                          style: GoogleFonts.poppins(
                            color: date != null
                                ? (themeChange.getThem() ? Colors.white : Colors.black)
                                : Colors.grey[600],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Front Side Image (if required)
          if (document.frontSide == true) ...[
            Text(
              "Front Side".tr,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildImageUploadBox(
              context,
              controller,
              '${document.id}_front',
              "Upload front side".tr,
              themeChange,
            ),
            const SizedBox(height: 16),
          ],

          // Back Side Image (if required)
          if (document.backSide == true) ...[
            Text(
              "Back Side".tr,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildImageUploadBox(
              context,
              controller,
              '${document.id}_back',
              "Upload back side".tr,
              themeChange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadBox(BuildContext context, DriverInfoController controller, String key, String hint, DarkThemeProvider themeChange) {
    return Obx(() {
      String? imagePath = controller.documentImages[key];
      
      return GestureDetector(
        onTap: () {
          String documentId = key.split('_')[0];
          bool isFrontSide = key.endsWith('_front');
          controller.pickDocumentImage(documentId, isFrontSide: isFrontSide);
        },
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder,
              style: BorderStyle.solid,
              width: 2,
            ),
          ),
          child: imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imagePath.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                        )
                      : Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                        ),
                )
              : DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  dashPattern: const [8, 4],
                  color: themeChange.getThem() ? AppColors.darkTextFieldBorder : AppColors.textFieldBorder,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hint,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }

  void _showZoneSelectionDialog(BuildContext context, DriverInfoController controller) {
    Get.dialog(
      AlertDialog(
        title: Text("Select Operating Zones".tr),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() => ListView.builder(
            itemCount: controller.zoneList.length,
            itemBuilder: (context, index) {
              ZoneModel zone = controller.zoneList[index];
              bool isSelected = controller.selectedZoneIds.contains(zone.id);
              
              return CheckboxListTile(
                title: Text(zone.name ?? ''),
                value: isSelected,
                onChanged: (bool? value) {
                  if (value == true) {
                    controller.selectedZoneIds.add(zone.id!);
                  } else {
                    controller.selectedZoneIds.remove(zone.id);
                  }
                  controller.updateSelectedZones();
                },
                activeColor: AppColors.primary,
              );
            },
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel".tr),
          ),
          TextButton(
            onPressed: () {
              if (controller.selectedZoneIds.isNotEmpty) {
                Get.back();
              } else {
                Get.snackbar("Error", "Please select at least one zone");
              }
            },
            child: Text("Done".tr),
          ),
        ],
      ),
    );
  }
}