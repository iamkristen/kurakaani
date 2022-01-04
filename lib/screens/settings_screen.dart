import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kurakaani/constants/app_constants.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/models/chat_user.dart';
import 'package:kurakaani/providers/settings_provider.dart';
import 'package:kurakaani/widgets/loading_view.dart';
import 'package:provider/src/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController nicknameController = TextEditingController();
  TextEditingController aboutMeController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  String dialCodeDigit = "+977";
  String id = "";
  String nickname = "";
  String aboutMe = "";
  String photoUrl = "";
  String phoneNumber = "";
  bool isLoading = false;
  File? avtarImageFile;
  late SettingsProvider settingsProvider;
  FocusNode nicknameFocusNode = FocusNode();
  FocusNode aboutMeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    settingsProvider = context.read<SettingsProvider>();
    readLocal();
  }

  readLocal() {
    setState(() {
      id = settingsProvider.getprefs(FirestoreConstants.id) ?? "";
      nickname = settingsProvider.getprefs(FirestoreConstants.nickname) ?? "";
      aboutMe = settingsProvider.getprefs(FirestoreConstants.aboutMe) ?? "";
      photoUrl = settingsProvider.getprefs(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          settingsProvider.getprefs(FirestoreConstants.phoneNumber) ?? "";
    });

    nicknameController.text = nickname;
    aboutMeController.text = aboutMe;
    if (phoneNumber.isNotEmpty) {
      phoneNumberController.text =
          phoneNumber.substring(phoneNumber.indexOf(' '));
    }
  }

  uploadFile() async {
    String filename = id;
    UploadTask uploadTask =
        settingsProvider.uploadFile(avtarImageFile!, filename);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();

      ChatUser updateInfo = ChatUser(
          id: id,
          photoUrl: photoUrl,
          nickName: nickname,
          aboutMe: aboutMe,
          phoneNumber: phoneNumber);
      settingsProvider
          .updateDataFirestore(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((data) async {
        await settingsProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      }).catchError((err) {
        setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: err.toString());
      });
    } on FirebaseException catch (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.message ?? err.toString());
    }
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? file = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err);
    });
    File? image;
    if (file != null) {
      image = File(file.path);
    }
    if (image != null) {
      setState(() {
        avtarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  buildTextField(
      {String? label,
      String? prefix,
      String? hint,
      String? error,
      TextEditingController? controller,
      void Function(String)? onChanged,
      FocusNode? focusNode,
      TextInputType? keyboardType}) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          style: const TextStyle(color: ColorConstants.primaryText),
          cursorColor: ColorConstants.primaryColor,
          decoration: InputDecoration(
            prefix: Text(prefix ?? ""),
            prefixStyle: const TextStyle(color: ColorConstants.primaryColor),
            errorText: error,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey),
            labelText: label,
            labelStyle: TextStyle(color: ColorConstants.primaryColor),
            fillColor: Colors.white,
            focusColor: Theme.of(context).primaryColor,
            filled: true,
          ),
          onChanged: onChanged,
          focusNode: focusNode,
          keyboardType: keyboardType,
        ));
  }

  handleUpdateData() {
    nicknameFocusNode.unfocus();
    aboutMeFocusNode.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigit != "+00" && phoneNumberController.text != "") {
        phoneNumber =
            dialCodeDigit + " " + phoneNumberController.text.toString();
      }
    });
    ChatUser updateInfo = ChatUser(
        id: id,
        photoUrl: photoUrl,
        nickName: nickname,
        aboutMe: aboutMe,
        phoneNumber: phoneNumber);
    settingsProvider
        .updateDataFirestore(
      FirestoreConstants.pathUserCollection,
      id,
      updateInfo.toJson(),
    )
        .then((data) async {
      // await settingsProvider.setPrefs(FirestoreConstants.id, id);
      await settingsProvider.setPrefs(FirestoreConstants.nickname, nickname);
      await settingsProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);
      await settingsProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
      await settingsProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Update Succcess");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppConstants.profile),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CupertinoButton(
                onPressed: getImage,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                      child: avtarImageFile == null
                          ? photoUrl.isNotEmpty
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .scaffoldBackgroundColor,
                                        shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(3),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: Stack(children: [
                                        Image.network(photoUrl,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100, errorBuilder:
                                                (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.account_circle,
                                            color: ColorConstants.primaryColor,
                                            size: 100,
                                          );
                                        }, loadingBuilder: (context, child,
                                                loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                  value: loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null &&
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null),
                                            ),
                                          );
                                        }),
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                              height: 25,
                                              width: 100,
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              child: const Icon(
                                                Icons.add_a_photo,
                                                color: Colors.white70,
                                              )),
                                        )
                                      ]),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.account_circle,
                                  color: ColorConstants.primaryColor,
                                  size: 100,
                                )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(45),
                              child: Image.file(
                                avtarImageFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildTextField(
                      label: "Name",
                      hint: "Update Nickname",
                      error: "",
                      controller: nicknameController,
                      onChanged: (value) {
                        nickname = value;
                      },
                      focusNode: nicknameFocusNode),
                  buildTextField(
                      label: "About Me",
                      hint: "Write about yourself...",
                      error: "",
                      controller: aboutMeController,
                      onChanged: (value) {
                        aboutMe = value;
                      },
                      focusNode: aboutMeFocusNode),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height: 55,
                      width: MediaQuery.of(context).size.width,
                      decoration: const BoxDecoration(
                        color: ColorConstants.primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsetsDirectional.only(bottom: 1),
                        decoration: const BoxDecoration(
                            color: ColorConstants.secondaryText,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4))),
                        height: 55,
                        width: MediaQuery.of(context).size.width,
                        child: CountryCodePicker(
                          onChanged: (country) {
                            setState(() {
                              dialCodeDigit = country.dialCode!;
                            });
                          },
                          textStyle: const TextStyle(
                              color: ColorConstants.primaryText),
                          dialogBackgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          dialogTextStyle: Theme.of(context)
                              .textTheme
                              .headline1!
                              .copyWith(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                          alignLeft: true,
                          hideSearch: true,
                          initialSelection: 'NP',
                          showCountryOnly: false,
                          showOnlyCountryWhenClosed: true,
                          favorite: const ['+977', "NP", "+91", "IN"],
                        ),
                      ),
                    ),
                  ),
                  buildTextField(
                    prefix: dialCodeDigit,
                    label: "Phone Number",
                    hint: "Update Phone Number",
                    error: "",
                    controller: phoneNumberController,
                    onChanged: (value) {
                      phoneNumber = value;
                    },
                    keyboardType: TextInputType.number,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: handleUpdateData,
                      child: Text("Update Now",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText2!
                              .copyWith(
                                  fontSize: 18, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                          elevation: 4,
                          shadowColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                          backgroundColor: Theme.of(context).primaryColor,
                          primary: ColorConstants.primaryText,
                          minimumSize: Size(
                              MediaQuery.of(context).size.width * 0.5, 40)),
                    ),
                  )
                ],
              )
            ]),
          ),
          isLoading ? const LoadingView() : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
