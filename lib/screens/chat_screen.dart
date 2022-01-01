import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kurakaani/constants/constants.dart';
import 'package:kurakaani/models/message_chat.dart';
import 'package:kurakaani/providers/auth_provider.dart';
import 'package:kurakaani/providers/chat_provider.dart';

import 'package:kurakaani/screens/full_photo.dart';
import 'package:kurakaani/screens/login_screen.dart';
import 'package:kurakaani/widgets/loading_view.dart';
import 'package:kurakaani/widgets/progress.dart';
import 'package:provider/src/provider.dart';

import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    Key? key,
    required this.peerId,
    required this.peerAvtar,
    required this.peerNickname,
    required this.peerPhoneNumber,
  }) : super(key: key);

  final String peerId;
  final String peerAvtar;
  final String peerNickname;
  final String peerPhoneNumber;

  @override
  _ChatScreenState createState() => _ChatScreenState(
      peerId: this.peerId,
      peerAvtar: this.peerAvtar,
      peerNickname: this.peerNickname,
      peerPhoneNumber: this.peerPhoneNumber);
}

class _ChatScreenState extends State<ChatScreen> {
  _ChatScreenState(
      {required this.peerId,
      required this.peerAvtar,
      required this.peerNickname,
      required this.peerPhoneNumber});
  String peerId;
  String peerAvtar;
  String peerNickname;
  String peerPhoneNumber;
  late String currentUserId;
  File? imageFile;

  List<QueryDocumentSnapshot> listMessage = List.from([]);
  int _limit = 20;
  int _limitIncrement = 20;
  String groupChatId = "";

  File? file;
  bool isLoading = false;
  bool isShowSticker = false;
  String imgUrl = "";

  TextEditingController textEditingController = TextEditingController();
  ScrollController listScrollController = ScrollController();
  FocusNode focusNode = FocusNode();

  late ChatProvider chatProvider;
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    chatProvider = context.read<ChatProvider>();
    focusNode.addListener(onFocusChange);
    listScrollController.addListener(_scrollListener);
    readLocal();
  }

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  onFocusChange() {
    if (focusNode.hasFocus) {
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() {
    if (authProvider.getUserFirebaseId()!.isNotEmpty) {
      currentUserId = authProvider.getUserFirebaseId()!;
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false);
    }
    if (currentUserId.hashCode <= peerId.hashCode) {
      groupChatId = '$currentUserId - $peerId';
    } else {
      groupChatId = '$peerId - $currentUserId';
    }
    chatProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
        currentUserId, {FirestoreConstants.chattingWith: peerId});
  }

  void getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;
    pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((err) {
      Fluttertoast.showToast(msg: err);
    });
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      if (imageFile != null) {
        setState(() {
          isLoading = true;
        });
        uploadFile();
      }
    }
  }

  void getSticker() {
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    UploadTask uploadFile = chatProvider.uploadFile(imageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadFile;
      imgUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imgUrl, TypeMessage.image);
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
        Fluttertoast.showToast(msg: e.message ?? e.toString());
      });
    }
  }

  onSendMessage(String content, int type) {
    if (content.trim().isNotEmpty) {
      textEditingController.clear();
      chatProvider.sendMessage(
          content, type, groupChatId, currentUserId, peerId);
      listScrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
          msg: "Nothing To Send",
          backgroundColor: ColorConstants.greyColor2.withOpacity(0.6));
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage[index - 1].get(FirestoreConstants.idFrom) ==
                currentUserId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        listMessage[index - 1].get(FirestoreConstants.idFrom) !=
            currentUserId)) {
      return true;
    } else {
      return false;
    }
  }

  void _callPhoneNumber(String callPhoneNumber) async {
    String url = "tel:$callPhoneNumber";
    await launch(url);
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      chatProvider.updateDataFirestore(FirestoreConstants.pathUserCollection,
          currentUserId, {FirestoreConstants.chattingWith: null});
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          peerNickname,
          style: const TextStyle(
              fontSize: 40, fontFamily: 'signatra', letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // SettingsProvider settingsProvider;
              // settingsProvider = context.read<SettingsProvider>();
              // String phoneNumber =
              //     settingsProvider.getprefs(FirestoreConstants.phoneNumber)!;
              _callPhoneNumber(peerPhoneNumber);
            },
            icon: const Icon(
              Icons.phone_iphone,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Stack(
          children: [
            Column(
              children: [
                buildListMessage(),
                isShowSticker ? buildSticker() : const SizedBox.shrink(),
                buildInput(),
              ],
            ),
            buildLoading(),
          ],
        ),
      ),
    );
  }

  Widget buildInput() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 0.5, color: Theme.of(context).primaryColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.camera_enhance,
            ),
            onPressed: getImage,
          ),
          IconButton(
            icon: const Icon(Icons.face_retouching_natural),
            onPressed: getSticker,
          ),
          Flexible(
            child: TextField(
              onSubmitted: (value) {
                onSendMessage(textEditingController.text, TypeMessage.text);
              },
              controller: textEditingController,
              cursorColor: ColorConstants.primaryColor,
              decoration: const InputDecoration.collapsed(
                hintText: "Type Your Message...",
              ),
              focusNode: focusNode,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () =>
                onSendMessage(textEditingController.text, TypeMessage.text),
          ),
        ],
      ),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatProvider.getChatSnapshot(groupChatId, _limit),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  listMessage.addAll(snapshot.data!.docs);
                  return ListView.builder(
                    controller: listScrollController,
                    reverse: true,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) =>
                        buildItem(index, snapshot.data!.docs[index]),
                  );
                } else {
                  return circularProgress();
                }
              })
          : circularProgress(),
    );
  }

  Widget buildLoading() {
    return isLoading ? const LoadingView() : const SizedBox.shrink();
  }

  Widget buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      MsgChat msgChat = MsgChat.fromDocument(document);
      if (msgChat.idFrom == currentUserId) {
        return Row(
          children: [
            msgChat.type == TypeMessage.text
                ? IntrinsicWidth(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: Text(
                        msgChat.content,
                        style: const TextStyle(
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6),
                      decoration: BoxDecoration(
                          color: ColorConstants.greyColor2,
                          borderRadius: BorderRadius.circular(8.0)),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 2 : 4,
                          top: 4,
                          right: 10),
                    ),
                  )
                : msgChat.type == TypeMessage.image
                    ? Container(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        FullPhoto(imgUrl: msgChat.content)));
                          },
                          child: Material(
                            child: Image.network(
                              msgChat.content,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                      color: ColorConstants.greyColor2,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: Theme.of(context).primaryColor,
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
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Material(
                                  child: Image.asset(
                                    "assets/images/img_not_available.jpeg",
                                    fit: BoxFit.cover,
                                    width: 200,
                                    height: 200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  clipBehavior: Clip.hardEdge,
                                );
                              },
                              fit: BoxFit.cover,
                              height: 200,
                              width: 200,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            clipBehavior: Clip.hardEdge,
                          ),
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 2 : 4,
                            top: 4,
                            right: 10),
                      )
                    : Container(
                        child: Image.asset(
                          "assets/images/${msgChat.content}.gif",
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 2 : 4,
                            top: 4,
                            right: 10),
                      ),
          ],
          mainAxisAlignment: MainAxisAlignment.end,
        );
      } else {
        return Column(
          children: [
            Row(
              children: [
                isLastMessageLeft(index)
                    ? Material(
                        child: Image.network(peerAvtar,
                            loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                                color: Theme.of(context).primaryColor,
                                value: loadingProgress.expectedTotalBytes !=
                                            null &&
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null),
                          );
                        }, errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.account_circle,
                            size: 35,
                            color: Theme.of(context).primaryColor,
                          );
                        }, width: 35, height: 35, fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(
                        width: 35,
                      ),
                (msgChat.type == TypeMessage.text)
                    ? IntrinsicWidth(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            msgChat.content,
                            style: const TextStyle(color: Colors.white),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.6,
                          ),
                          decoration: BoxDecoration(
                              color: ColorConstants.primaryColor,
                              borderRadius: BorderRadius.circular(8)),
                          margin: EdgeInsets.only(
                              bottom: isLastMessageLeft(index) ? 2 : 4,
                              top: isLastMessageLeft(index) ? 2 : 4,
                              left: 10),
                        ),
                      )
                    : (msgChat.type == TypeMessage.image)
                        ? Container(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FullPhoto(
                                            imgUrl: msgChat.content)));
                              },
                              child: Material(
                                child: Image.network(
                                  msgChat.content,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                          color: ColorConstants.greyColor2,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                            color:
                                                Theme.of(context).primaryColor,
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
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Material(
                                      child: Image.asset(
                                        "assets/images/img_not_available.jpeg",
                                        fit: BoxFit.cover,
                                        width: 200,
                                        height: 200,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      clipBehavior: Clip.hardEdge,
                                    );
                                  },
                                  fit: BoxFit.cover,
                                  height: 200,
                                  width: 200,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                clipBehavior: Clip.hardEdge,
                              ),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero),
                            ),
                            margin: EdgeInsets.only(
                                bottom: isLastMessageLeft(index) ? 2 : 4,
                                top: isLastMessageLeft(index) ? 2 : 4,
                                left: 10),
                          )
                        : Container(
                            child: Image.asset(
                              "assets/images/${msgChat.content}.gif",
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(
                                bottom: isLastMessageLeft(index) ? 2 : 4,
                                top: isLastMessageLeft(index) ? 2 : 4,
                                left: 10),
                          ),
              ],
            ),
            isLastMessageLeft(index)
                ? Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 6, left: 50),
                    child: Text(
                      DateFormat('dd MMM yyyy, hh:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(msgChat.timestamp),
                        ),
                      ),
                      style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        );
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildSticker() {
    return Expanded(
        child: Container(
      height: 180,
      decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).primaryColor, width: 2),
          ),
          color: Theme.of(context).scaffoldBackgroundColor),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () => onSendMessage("mimi1", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi1.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                  onPressed: () => onSendMessage("mimi2", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi2.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                  onPressed: () => onSendMessage("mimi3", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi3.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () => onSendMessage("mimi4", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi4.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                  onPressed: () => onSendMessage("mimi5", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi5.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                  onPressed: () => onSendMessage("mimi6", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi6.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () => onSendMessage("mimi7", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi7.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                  onPressed: () => onSendMessage("mimi8", TypeMessage.sticker),
                  child: Image.asset(
                    "assets/images/mimi8.gif",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                  )),
              TextButton(
                onPressed: () => onSendMessage("mimi9", TypeMessage.sticker),
                child: Image.asset(
                  "assets/images/mimi9.gif",
                  fit: BoxFit.cover,
                  height: 50,
                  width: 50,
                ),
              ),
            ],
          )
        ],
      ),
    ));
  }
}
