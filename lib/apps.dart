import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  void initState() {
    super.initState();
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
                IconButton(
                  icon: Icon(
                      mode == DisplayMode.Grid ? Icons.list : Icons.grid_on),
                  onPressed: () async {
                    if (mode == DisplayMode.Grid) {
                      bool result = await _showPasswordDialog(context);
                      if (result) {
                        ref.read(modeProvider.notifier).update((state) =>
                            state == DisplayMode.Grid
                                ? DisplayMode.List
                                : DisplayMode.Grid);
                      }
                    } else {
                      ref.read(modeProvider.notifier).update((state) =>
                          state == DisplayMode.Grid
                              ? DisplayMode.List
                              : DisplayMode.Grid);
                    }
                  },
                  iconSize: 40,
                )
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
                              .where(
                                (app) => packageNames.any(
                                    (name) => app.packageName.startsWith(name)),
                              )
                              .map((app) => AppGridItem(
                                    application: app as ApplicationWithIcon?,
                                  ))
                        ],
                      ),
                loading: () => CircularProgressIndicator(),
                error: (e, s) => Container()));
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
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
                      if (enteredPassword == '9999') {
                        // Mật khẩu đúng, trả về true
                        Navigator.pop(context, true);
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
