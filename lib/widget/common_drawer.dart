import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/model/user_model.dart';
import 'package:wonmore_money_book/provider/money/money_provider.dart';
import 'package:wonmore_money_book/provider/todo_provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';

class CommonDrawer extends StatefulWidget {
  final GlobalKey? groupSyncKey;
  final GlobalKey? currentBudgetKey;
  final GlobalKey? shareJoinKey;

  const CommonDrawer({
    super.key,
    this.groupSyncKey,
    this.currentBudgetKey,
    this.shareJoinKey,
  });

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer> {
  // 현재 선택된 가계부 이름
  late String selectedBudgetName;

  @override
  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final moneyProvider = context.watch<MoneyProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.loadSharedUsers();
    });

    if (!userProvider.isLoggedIn) {
      return Drawer(
          backgroundColor: const Color(0xFFF2F4F6),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountEmail: const SizedBox.shrink(),
                accountName: Text(
                  '사용자 이름',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                currentAccountPicture: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: Colors.black, size: 40)),
                decoration: const BoxDecoration(color: Color(0xFF635BFF)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '로그인이 필요합니다',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('사용자 초대'),
                onTap: handleInviteUser,
              ),

              // 로그아웃 버튼
              ListTile(
                leading: Icon(Icons.login),
                title: Text('로그인'),
                onTap: handleLogin,
              ),
            ],
          ));
    }
    final userId = userProvider.userId;
    final sharedUser = userProvider.sharedUsers;
    final myInfo = userProvider.myInfo;
    final userName = myInfo?.name ?? '이름 없음';
    final isProfile = myInfo?.isProfile ?? false;
    final isLoggedIn = userProvider.isLoggedIn;
    final ownerId = userProvider.ownerId;
    final budgetId = userProvider.budgetId;
    final sharedOwnerIds = userProvider.sharedOwnerIds;
    final sharedOwnerUsers = userProvider.sharedOwnerUsers ?? [];
    final budgets = userProvider.budgets;
    final selectedBudgetName = (budgets != null && budgets.isNotEmpty)
        ? budgets
        .firstWhere(
          (b) => b.id == budgetId,
      orElse: () => budgets.first,
    )
        .name
        : '(가계부 없음)';

    final ownerName = () {
      final hit = sharedOwnerUsers.firstWhere(
            (u) => u.id == ownerId,
        orElse: () => myInfo ?? UserModel(),
      );
      return hit.name ?? (myInfo?.name ?? '사용자');
    }();

    final selectedGroupName = '$ownerName의 그룹'; // ← 이렇게 표시

    return Drawer(
      backgroundColor: const Color(0xFFF2F4F6),
      child: Column(
        children: [
          // 상단: 유저 정보
          UserAccountsDrawerHeader(
            accountEmail: const SizedBox.shrink(),
            accountName: Padding(
              padding: const EdgeInsets.only(top: 22.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      userName ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/more/my-info');
                    },
                  ),
                ],
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: isProfile ? NetworkImage(myInfo?.profileUrl ?? '') : null,
              child: !isProfile ? Icon(Icons.person, color: Colors.black, size: 40) : null,
            ),
            decoration: const BoxDecoration(color: Color(0xFF635BFF)),
          ),

          // 현재 가계부 전환 UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '가계부 그룹',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedGroupName ?? '(그룹 없음)',
                      style:
                      TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      key: widget.groupSyncKey,
                      icon: const Icon(Icons.sync, size: 20, color: Colors.grey),
                      onPressed: () async {
                        if (sharedOwnerUsers.isEmpty) return;

                        final selectedId = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            // ✅ 오너 목록 (내 오너 정보가 리스트에 없을 수 있으니 보정)
                            final owners = [...(userProvider.sharedOwnerUsers ?? [])];
                            if (!owners.any((u) => u.id == userProvider.userId) && userProvider.myInfo != null) {
                              owners.insert(0, userProvider.myInfo!);
                            }
                            return SimpleDialog(
                              title: const Text('그룹 선택'),
                              children: owners.map((user) {
                                final gid = user.id ?? '';
                                final title = '${(user.name ?? '사용자')}의 그룹';
                                final isCurrent = gid == ownerId;
                                return SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, gid),
                                  child: Row(
                                    children: [
                                      if (isCurrent) const Icon(Icons.check, color: Colors.green, size: 20),
                                      const SizedBox(width: 4),
                                      Text(title),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );

                        if (selectedId != null && selectedId != ownerId) {
                          await userProvider.setOwnerId(selectedId);
                          final newBudgetId = userProvider.budgetId;
                          await moneyProvider.setOwnerId(
                              selectedId, newBudgetId!); // provider에 메서드가 있어야 함
                          await context.read<TodoProvider>().setUserId(userId, selectedId);
                        }
                      },
                    ),
                  ],
                ),
                const Text(
                  '현재 가계부',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: widget.currentBudgetKey,
                      isExpanded: true,
                      value: budgets?.any((b) => b.id == budgetId) == true ? budgetId : null,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      items: budgets?.map((budget) {
                        return DropdownMenuItem<String>(
                          value: budget.id,
                          child: Text(budget.name ?? '(이름 없음)'),
                        );
                      }).toList(),
                      onChanged: (newValue) async {
                        if (newValue != null) {
                          await userProvider.setBudgetId(newValue);
                          await moneyProvider.setBudgetId(newValue);
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 함께 쓰는 사용자 리스트
          Text(
            '함께하는 유저',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: (sharedUser == null || sharedUser.isEmpty)
                ? Center(child: Text('로그인이 필요합니다'))
                : Builder(builder: (context) {
              final sortedUsers = [...sharedUser]; // 원본 리스트 복사
              final ownerId = context.read<UserProvider>().ownerId;

              // 정렬 로직
              sortedUsers.sort((a, b) {
                if (a.id == ownerId) return -1;
                if (b.id == ownerId) return 1;
                return a.name!.compareTo(b.name!);
              });

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(sortedUsers.length, (index) {
                    print(sortedUsers.length);
                    final user = sortedUsers[index];
                    final isOwner = user.id == ownerId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage:
                        user.isProfile! ? NetworkImage(user.profileUrl!) : null,
                        child: !user.isProfile!
                            ? Icon(Icons.group, color: Colors.black, size: 40)
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name!,
                              style: TextStyle(
                                fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          if (isOwner) const Text('👑'), // 오른쪽 끝에 왕관
                        ],
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          // Expanded(
          //   child: (sharedUser == null || sharedUser.isEmpty)
          //       ? Center(child: Text('로그인이 필요합니다'))
          //       : SingleChildScrollView(
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: List.generate(sharedUser.length, (index) {
          //         final user = sharedUser[index];
          //         return ListTile(
          //           leading: CircleAvatar(
          //             radius: 24,
          //             backgroundColor: Colors.white,
          //             backgroundImage: user.isProfile!
          //                 ? NetworkImage(user.profileUrl!)
          //                 : null,
          //             child: !user.isProfile!
          //                 ? Icon(Icons.group, color: Colors.black, size: 40)
          //                 : null,
          //           ),
          //           title: Text(user.name!),
          //         );
          //       }),
          //     ),
          //   ),
          // ),
          const Divider(),

          // 사용자 초대 버튼
          ListTile(
            key: widget.shareJoinKey,
            leading: const Icon(Icons.person_add),
            title: const Text('가계부 그룹 공유/참여'),
            onTap: handleInviteUser,
          ),

          // 로그아웃 버튼
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('로그아웃'),
            onTap: handleLogout,
          ),
        ],
      ),
    );
  }

  void handleInviteUser() {
    final isLoggedIn = context.read<UserProvider>().isLoggedIn;

    if (!isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(message: '이 기능은 로그인 후 사용할 수 있습니다.'),
        ),
      );
      return;
    }

    Navigator.pushNamed(context, '/more/join-group');
  }

  void handleLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void handleLogout() async {
    final userProvider = context.read<UserProvider>();

    /// TODO: 이거 나중에 provider를 매개변수로 받을지 말지 고민해보자
    await userProvider.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}