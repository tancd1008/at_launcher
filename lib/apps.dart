import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_state.dart';

final modeProvider = StateProvider<DisplayMode>((ref) => DisplayMode.Grid);
final packageNames = [
  'com.example.project_01',
  'com.appwhoosh.vietktvremote',
  'com.atvn_customer',
];

class AppsPage extends StatefulWidget {
  const AppsPage({Key? key}) : super(key: key);
  @override
  _AppsPageState createState() => _AppsPageState();
}

enum DisplayMode {
  Grid,
  List,
}

class _AppsPageState extends State<AppsPage>
    with AutomaticKeepAliveClientMixin {
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer(
      builder: (context, ref, _) {
        final appsInfo = ref.watch(appsProvider);
        final mode = ref.watch(modeProvider);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            elevation: 0,
            actionsIconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            backgroundColor: Colors.transparent,
            actions: [
              if (!(mode == DisplayMode.Grid))
                IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    _showUpdateDialog(context);
                  },
                  iconSize: 40,
                ),
              IconButton(
                icon:
                    Icon(mode == DisplayMode.Grid ? Icons.list : Icons.grid_on),
                onPressed: () async {
                  bool hasPassword = _prefs.containsKey('password');
                  if (hasPassword) {
                    bool result = await _showPasswordDialog(context);
                    if (result) {
                      ref.read(modeProvider.notifier).update((state) =>
                          state == DisplayMode.Grid
                              ? DisplayMode.List
                              : DisplayMode.Grid);
                    }
                  } else {
                    await _showCreatePasswordDialog(context);
                    bool hasPasswordAfterCreation =
                        _prefs.containsKey('password');
                    if (hasPasswordAfterCreation) {
                      bool result = await _showPasswordDialog(context);
                      if (result) {
                        ref.read(modeProvider.notifier).update((state) =>
                            state == DisplayMode.Grid
                                ? DisplayMode.List
                                : DisplayMode.Grid);
                      }
                    }
                  }
                },
                iconSize: 40,
              ),
            ],
          ),
          body: appsInfo.when(
            data: (List<Application> apps) => mode == DisplayMode.List
                ? ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (BuildContext context, int index) {
                      ApplicationWithIcon app =
                          apps[index] as ApplicationWithIcon;
                      return ListTile(
                        leading: Image.memory(
                          app.icon,
                          width: 40,
                        ),
                        title: Text(app.appName),
                        onTap: () => DeviceApps.openApp(app.packageName),
                      );
                    },
                  )
                : GridView(
                    padding: const EdgeInsets.fromLTRB(
                        16.0, kToolbarHeight + 16.0, 16.0, 16.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    children: [
                      ...apps
                          .where((app) => packageNames
                              .any((name) => app.packageName.startsWith(name)))
                          .map((app) => AppGridItem(
                                application: app as ApplicationWithIcon?,
                              ))
                    ],
                  ),
            loading: () => CircularProgressIndicator(),
            error: (e, s) => Container(),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _showUpdateDialog(BuildContext context) async {
    bool result = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Cập nhật'),
              content: Text('Bạn có muốn cập nhật?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text('Cập nhật'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (result) {
      // Thực hiện hành động cập nhật ở đây
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đang cập nhật...')),
      );
      await launchUrl(Uri.parse('https://app.atpos.net/launcher.apk'));
    }
  }

  Future<bool> _showPasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    String enteredPassword = ''; // Mật khẩu người dùng nhập

    bool result = await showDialog<bool>(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Nhập mật khẩu'),
                  content: TextField(
                    controller: passwordController,
                    obscureText: true,
                    onChanged: (value) {
                      enteredPassword = value;
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, false); // Trả về false khi hủy
                      },
                      child: Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Đóng dialog
                        _showUpdatePasswordDialog(
                            context); // Hiển thị popup cập nhật mật khẩu
                      },
                      child: Text('Cập nhật'),
                    ),
                    TextButton(
                      onPressed: () {
                        String storedPassword =
                            _prefs.getString('password') ?? '';
                        if (enteredPassword == storedPassword) {
                          Navigator.pop(
                              context, true); // Trả về true nếu mật khẩu đúng
                        } else {
                          // Mật khẩu không đúng, hiển thị thông báo và không đóng dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Mật khẩu không đúng'),
                            ),
                          );
                          // Xóa nội dung đã nhập
                          passwordController.clear();
                        }
                      },
                      child: Text('Xác nhận'),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false; // Mặc định trả về false nếu showDialog trả về null

    return result;
  }

  Future<void> _showUpdatePasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    String enteredPassword = ''; // Mật khẩu người dùng nhập

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Cập nhật mật khẩu'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                onChanged: (value) {
                  enteredPassword = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                  },
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () async {
                    _prefs.setString('password', enteredPassword);
                    Navigator.pop(context); // Đóng dialog cập nhật mật khẩu

                    // Hiển thị thông báo khi đổi mật khẩu thành công bằng ScaffoldMessenger
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đổi mật khẩu thành công'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreatePasswordDialog(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();
    String enteredPassword = ''; // Mật khẩu người dùng nhập

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tạo mật khẩu mới'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                onChanged: (value) {
                  enteredPassword = value;
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng dialog
                  },
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    _prefs.setString('password', enteredPassword);
                    Navigator.pop(context); // Đóng dialog tạo mật khẩu
                  },
                  child: Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class AppGridItem extends StatelessWidget {
  final ApplicationWithIcon? application;
  const AppGridItem({
    this.application,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        DeviceApps.openApp(application!.packageName);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Image.memory(
              application!.icon,
              fit: BoxFit.contain,
              width: 40,
            ),
          ),
          Text(
            application!.appName,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
