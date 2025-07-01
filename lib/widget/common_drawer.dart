import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wonmore_money_book/provider/user_provider.dart';
import 'package:wonmore_money_book/screen/login_screen.dart';

class CommonDrawer extends StatefulWidget {
  const CommonDrawer({super.key});

  @override
  State<CommonDrawer> createState() => _CommonDrawerState();
}

class _CommonDrawerState extends State<CommonDrawer> {

  /// TODO: 가계부 이름도 추가할 수 있어야 겠다. 없을 경우 userName의 가계부 로

  // 현재 선택된 가계부 이름
  late String selectedBudgetName;

  // 함께 사용하는 사용자들
  final List<SharedUser> sharedUsers = [
    SharedUser(name: '이엄마', role: 'owner'),
    SharedUser(name: '신철원', role: 'editor'),
    SharedUser(name: '아이', role: 'viewer'),
  ];

  @override

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

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
                child: Icon(Icons.person, color: Colors.black, size: 40)
              ),
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
        )
      );
    }
    final userId = userProvider.userId;
    final sharedUser = userProvider.sharedUser;
    final myInfo = sharedUser?.firstWhere((user) => user.id == userId);
    final userName = myInfo?.name ?? '이름 없음';
    final isProfile = myInfo?.isProfile ?? false;
    final isLoggedIn = userProvider.isLoggedIn;
    final ownerId = userProvider.ownerId;
    final budgetId = userProvider.budgetId;
    final sharedOwnerIds = userProvider.sharedOwnerIds;
    final budgets = userProvider.budgets;
    final selectedBudgetName = (budgets != null && budgets.isNotEmpty)
        ? budgets.firstWhere((b) => b.id == budgetId,
          orElse: () => budgets.first,
          ).name
        : '(가계부 없음)';

    final selectedGroupName = (sharedUser != null && sharedUser.isNotEmpty)
        ? sharedUser.firstWhere(
          (u) => u.id == ownerId,
          orElse: () => sharedUser.first,
          ).groupName
        : '(그룹 없음)';

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
                  Text(
                    userName ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      // TODO: 설정 화면 이동
                      print('설정 눌림');
                    },
                  ),
                ],
              ),
            ),

            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: isProfile
                  ? NetworkImage(myInfo?.profileUrl ?? '')
                  : null,
              child: !isProfile
                  ? Icon(Icons.person, color: Colors.black, size: 40)
                  : null,
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
                      style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync, size: 20, color: Colors.grey),
                      onPressed: () {
                        // TODO: ownerId 변경 처리 로직 연결
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
                      isExpanded: true,
                      value: selectedBudgetName,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      items: budgets?.map((budget) {
                        return DropdownMenuItem<String>(
                          value: budget.name,
                          child: Text(budget.name ?? '(이름 없음)'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          context.read<UserProvider>().setOwnerId(newValue);
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
          Text('함께하는 유저',
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
                    final user = sortedUsers[index];
                    final isOwner = user.id == ownerId;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage: user.isProfile!
                            ? NetworkImage(user.profileUrl!)
                            : null,
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
                            ),
                          ),
                          if (isOwner)
                            const Text('👑'), // 오른쪽 끝에 왕관
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
            leading: const Icon(Icons.person_add),
            title: const Text('사용자 초대'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인이 필요합니다.'),
          duration: Duration(milliseconds: 1000),
        ),
      );

      Future.delayed(Duration(milliseconds: 1100), () {
        handleLogin();
      });
      return;
    }

    // 사용자 초대 로직 TODO : 만들어야함
    print('사용자 초대');
  }

  void handleLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void handleLogout() async {
    final userProvider = context.read<UserProvider>(); /// TODO: 이거 나중에 provider를 매개변수로 받을지 말지 고민해보자
    await userProvider.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}

// 공유 사용자 모델
class SharedUser {
  final String name;
  final String role;

  SharedUser({required this.name, required this.role});

  String get roleLabel {
    switch (role) {
      case 'owner':
        return '관리자';
      case 'editor':
        return '편집자';
      case 'viewer':
        return '보기 전용';
      default:
        return '알 수 없음';
    }
  }
}

// 가계부 그룹 모델
class BudgetGroup {
  final String name;
  final bool isOwner;

  BudgetGroup({required this.name, required this.isOwner});
}