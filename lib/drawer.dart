/// atonement - drawer
/// Created by xhz on 7/17/24

part of 'main.dart';

class _Drawer extends StatelessWidget {
  const _Drawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: CupertinoListSection.insetGrouped(
        backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
        header: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: const Text('信息'),
        ),
        children: [
          CupertinoListTile.notched(
            title: const Text('Google 登录'),
            onTap: kIsWeb ? null : handleNoWebGoogleSignIn,
            leading: Obx(() => NNAvatar(imageUrl: currentUser.value.photoUrl)),
            trailing: Obx(() => hasAccount ? Text(displayName) : buildSignInButton(onPressed: handleNoWebGoogleSignIn)),
          ),
          CupertinoListTile.notched(
            title: const Text('FCM Token'),
            leading: const Icon(Icons.key_rounded, color: CupertinoColors.systemIndigo),
            trailing: const Icon(CupertinoIcons.doc_on_doc, color: CupertinoColors.systemIndigo),
            onTap: () => Clipboard.setData(ClipboardData(text: fcmToken.value.toString())),
          ),
          const CupertinoListTile.notched(
            title: Text('初始化通知'),
            leading: Icon(CupertinoIcons.bell, color: CupertinoColors.systemYellow),
            trailing: CupertinoListTileChevron(),
            onTap: initNotification,
          ),
          // Switcher
        ],
      ),
    );
  }
}
